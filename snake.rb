require 'socket'
gs = TCPServer.open(1234)
addr = gs.addr
addr.shift
puts('server is on %s' % addr.join(':'))

# ここ参考に書いた
# https://stackoverflow.com/questions/4532344/send-data-over-telnet-without-pressing-enter/4532379
#
# 関連するtelnetのrfc
# https://tools.ietf.org/html/rfc854
# https://tools.ietf.org/html/rfc1184
# https://tools.ietf.org/html/rfc857
SB       = 250 # sequence beign
SE       = 240 # sequence end
WILL     = 251
DO       = 253
IAC      = 255
LINEMODE = 34
LM_MODE  = 1
ECHO     = 1

IAC_DO_LINEMODE = [IAC, DO, LINEMODE].pack('c*').freeze
IAC_SB_LINEMODE_0_IAC_SE = [IAC, SB, LINEMODE, LM_MODE, 0, IAC, SE].pack('c*').freeze
IAC_WILL_ECHO = [IAC, WILL, ECHO].pack('c*').freeze

SKIP_SIZE = 1000

CSI = "\x1b["
ERASE_ALL = '2'

CURSOR_UP="\e[A"
CURSOR_DOWN="\e[B"
CURSOR_RIGHT="\e[C"
CURSOR_LEFT="\e[D"

HEIGHT = 24
WIDTH  = 80

using Module.new {
  refine(Array) {
    def y; first; end
    def x; last; end
  }
}

def init_map
  Array.new(HEIGHT) { Array.new(WIDTH) { false } }
end

threads = []

def new_body_from(feeds, thread)
  new_body = thread.body.dup
  head = new_body.first
  tail = new_body.pop
  new_head =
    case thread.direction
    when CURSOR_UP
      [(head.y - 1) % HEIGHT, head.x]
    when CURSOR_DOWN
      [(head.y + 1) % HEIGHT, head.x]
    when CURSOR_RIGHT
      [head.y, (head.x + 1) % WIDTH]
    when CURSOR_LEFT
      [head.y, (head.x - 1) % WIDTH]
    else
      head
    end
  new_body.unshift(new_head)

  if feeds.delete([new_head.y, new_head.x])
    new_body.push(tail)
  end

  new_body
end


feeds = []
render_thread = Thread.start do
  map = init_map

  Thread.current.define_singleton_method(:map) { map }
  Thread.current.define_singleton_method(:blank_point) {
    loop {
      y = rand(1..HEIGHT)
      x = rand(1..WIDTH)

      break [y, x] unless map[y][x]
    }
  }

  loop do
    new_map = init_map
    threads.each do |t|
      t.body = new_body_from(feeds, t)
      t.body.each do |y,x|
        new_map[y][x] = t.player
      end
    end
    map = new_map

    threads.each do |t|
      threads.each do |t2|
        next if t == t2
        t.dead if t2.body.include?(t.body.first)
      end
    end

    if feeds.count < 3
      feeds << Thread.current.blank_point
    end

    feeds.each { |f| map[f.y][f.x] = '@' }

    sleep 0.1
  end
end


using Module.new {
  refine(TCPSocket) {
    def erase_all
      print CSI, ERASE_ALL, 'J'
    end

    def move_cursor_lefttop
      move_cursor(1, 1)
    end

    def erase_line
      print CSI, "K"
    end

    def move_cursor(row, column)
      print CSI, '%d;%dH' % [row, column]
    end

    define_method(:render) {
      move_cursor_lefttop
      render_thread.map.each.with_index(1) { |row,y|
        move_cursor(y, 1)
        erase_line
        print(row.map { |x| x ? x : ' ' }.join +  "\n")
      }
    }
  }
}

player = "A"

loop {
  threads << Thread.start(gs.accept) { |s|
    new_player = player
    player = player.next
    Thread.current.define_singleton_method(:player) { new_player }
    Thread.current.define_singleton_method(:s) { s }
    direction = CURSOR_RIGHT
    Thread.current.define_singleton_method(:direction) { direction }

    live = true
    Thread.current.define_singleton_method(:dead) { live = false }
    Thread.current.define_singleton_method(:live) { live }

    body = [render_thread.blank_point]
    Thread.current.define_singleton_method(:body=) {|new_body| body = new_body }
    Thread.current.define_singleton_method(:body) { body }
    puts('%s is accepted' % s)

    s.print(IAC_DO_LINEMODE)
    s.print(IAC_SB_LINEMODE_0_IAC_SE)
    s.print(IAC_WILL_ECHO)

    begin
      sleep 0.1
      s.read_nonblock(SKIP_SIZE)
    rescue IO::EAGAINWaitReadable
      retry
    end

    s.erase_all
    s.move_cursor_lefttop

    loop {
      begin
        direction = s.read_nonblock(3)
      rescue IO::EAGAINWaitReadable
        nil
      rescue EOFError
        break
      end

      s.render
      break unless Thread.current.live
    } rescue nil

    puts('%s is gone' % s)
    s.close
    threads.delete(Thread.current)
  }
}
