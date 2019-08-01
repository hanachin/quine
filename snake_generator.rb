C=File.read(__FILE__).split('AA'+'BB').last.gsub(/ +/, ' ').gsub(/^ +/, '')
# eval C
# exit

# AABB
require 'socket'

H = 80
W  = 24

# def render
#   formatted = C wo asciiaato ni kuuhaku ireru
#   puts "eval C=%w(#{formatted}).join"
# end

using Module.new {
  refine(Array) {
    define_method(:y) { first }
    define_method(:x) { last }
  }
}

m = nil
ts = []
fs = []

define_method(:new_body_from){|t|
  nb = t.b.dup
  h = nb.first
  e = nb.pop
  nh =
    case t.d
    when "\e[A"
      [(h.y - 1) % H, h.x]
    when "\e[B"
      [(h.y + 1) % H, h.x]
    when "\e[C"
      [h.y, (h.x + 1) % W]
    when "\e[D"
      [h.y, (h.x - 1) % W]
    else
      h
    end
  nb.unshift(nh)
  fs.delete([nh.y, nh.x]) && nb.push(e)
  nb
}


rt = Thread.start {
  Thread.current.define_singleton_method(:bp) {
    loop {
      x,y = rand(W),rand(H)
      break [y, x] if m[y][x] == ' '
    }
  }

  loop {
    nm = Array.new(H) { Array.new(W) { ' ' } }
    ts.each { |t|
      t.b = new_body_from(t)
      t.b.each { |y,x|
        nm[y][x] = t.p
      }
    }
    m = nm

    ts.each { |t|
      ts.each { |t2|
        t != t2 &&  t2.b.include?(t.b.first) && t.dead
      }
    }

    fs.size < 10 && fs << Thread.current.bp
    fs.each { m[@1][@2] = '@' }

    ci = 0
    m2 = Array.new(H*8) { Array.new(W*8) { ' ' } }
    m.each_with_index { |r, y|
      r.each_with_index { |c, x|
        if c == '@'
          8.times { |yi|
            ci+=8
            m2[y*8+yi][x..x+8] = C[ci-8..ci]
          }
        elsif c == ' '
          8.times { |yi|
            m2[y*8+yi][x...x+8] = ' ' * 8
          }
        else
          8.times { |yi|
            m2[y*8+yi][x...x+8] = (c * 6).inspect
          }
        end
      }
    }

    m2.each_with_index { |r,y|
      $stdout.print("\x1b[#{y+1};1H\x1b[K",*r)
    }

    sleep(1)
  }
}

p = ?A

gs = TCPServer.open(1234)

loop {
  ts << Thread.start(gs.accept) { |s|
    np = p
    p = p.next
    d = ""
    l = true
    b = [rt.bp]

    fn=Thread.current.:define_singleton_method
    fn.(:p) { np }
    fn.(:d) { d }
    fn.(:dead) { l= false }
    fn.(:b=) {|nb| b = nb }
    fn.(:b) { b }

    s.print([255, 253, 34, 255, 250, 34, 1, 0, 255, 240, 255, 251, 1].pack('c*'),"\x1b[2J\x1b[?12l")

    begin
      sleep(0.1)
      s.read_nonblock(999)
    rescue IO::EAGAINWaitReadable
      retry
    end

    loop {
      begin
        d = s.read_nonblock(3)
      rescue IO::EAGAINWaitReadable
        nil
      rescue
        break
      end

      m.each_with_index { |r,y|
        s.print("\x1b[#{y+1};1H\x1b[K",*r)
      }

      !l && break
    } rescue nil
    s.close;
    ts.delete(Thread.current)
  }
}
