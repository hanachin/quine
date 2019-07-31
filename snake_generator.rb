require 'socket'
gs = TCPServer.open(1234)



CSI = "\x1b["
ERASE_ALL = '2'

CURSOR_UP="\e[A"
CURSOR_DOWN="\e[B"
CURSOR_RIGHT="\e[C"
CURSOR_LEFT="\e[D"

HEIGHT = 24 - 1
WIDTH  = 80

using Module.new {
  refine(Array) {
    define_method(:y) { first }
    define_method(:x) { last }
  }
}

init_map = -> { Array.new(HEIGHT) { Array.new(WIDTH) { ' ' } } }

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
  map = init_map.call

  Thread.current.define_singleton_method(:map) { map }
  Thread.current.define_singleton_method(:blank_point) {
    loop {
      y = rand(1..HEIGHT)
      x = rand(1..WIDTH)

      break [y, x] if map[y][x] == ' '
    }
  }

  loop do
    new_map = init_map.call
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
    define_method(:erase_all) { print(CSI, ERASE_ALL, 'J')}
    define_method(:erase_line) { print CSI, 'K' }
    define_method(:move_cursor) {|r, c| print CSI, '%d;%dH' % [r, c] }
    define_method(:render) {
      render_thread.map.each.with_index(1) { |r,y|
        move_cursor(y, 1)
        erase_line
        print(r.join)
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

    s.print([255, 253, 34, 255, 250, 34, 1, 0, 255, 240, 255, 251, 1].pack('c*'))

    begin
      sleep 0.1
      s.read_nonblock(1000)
    rescue IO::EAGAINWaitReadable
      retry
    end

    s.erase_all

    loop {
      begin
        direction = s.read_nonblock(3)
      rescue IO::EAGAINWaitReadable
        nil
      rescue EOFError
        break
      end

      s.render
      !Thread.current.live && break
    } rescue nil

    puts('%s is gone' % s)
    s.close
    threads.delete(Thread.current)
  }
}
