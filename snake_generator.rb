require 'socket'

H = 24
W  = 80

using Module.new {
  refine(Array) {
    define_method(:y) { first }
    define_method(:x) { last }
  }
}

im = -> { Array.new(H) { Array.new(W) { ' ' } } }

ts = []
fs = []

define_method(:new_body_from){|t|
  nb = t.b.dup
  h = nb.first
  tail = nb.pop
  nh =
    case t.dir
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

  fs.delete([nh.y, nh.x]) && nb.push(tail)
  nb
}


rt = Thread.start {
  m = im.()
  Thread.current.define_singleton_method(:m) { m }
  Thread.current.define_singleton_method(:bp) {
    loop {
      y = rand(0...H)
      x = rand(0...W)
      break [y, x] if m[y][x] == ' '
    }
  }

  loop {
    nm = im.()
    ts.each { |t|
      t.b = new_body_from(t)
      t.b.each { |y,x|
        nm[y][x] = t.player
      }
    }
    m = nm

    ts.each { |t|
      ts.each { |t2|
        next if t == t2
        t2.b.include?(t.b.first) && t.dead
      }
    }

    fs.count < 3 && fs << Thread.current.bp

    fs.each { |f| m[f.y][f.x] = '@' }
    sleep(0.1)
  }
}

using Module.new {
  refine(TCPSocket) {
    define_method(:render) {
      rt.m.each_with_index { |r,y|
        print("\x1b[#{y+1};1H\x1b[K",*r)
      }
    }
  }
}

player = ?A

gs = TCPServer.open(1234)

loop {
  ts << Thread.start(gs.accept) { |s|
    new_player = player
    player = player.next
    Thread.current.define_singleton_method(:player) { new_player }
    Thread.current.define_singleton_method(:s) { s }

    dir = ""
    Thread.current.define_singleton_method(:dir) { dir }

    live = true
    Thread.current.define_singleton_method(:dead) { live = false }

    b = [rt.bp]
    Thread.current.define_singleton_method(:b=) {|nb| b = nb }
    Thread.current.define_singleton_method(:b) { b }

    s.print([255, 253, 34, 255, 250, 34, 1, 0, 255, 240, 255, 251, 1].pack('c*'))

    begin
      sleep(0.1)
      s.read_nonblock(1000)
    rescue IO::EAGAINWaitReadable
      retry
    end

    s.print("\x1b[2J")

    loop {
      begin
        dir = s.read_nonblock(3)
      rescue IO::EAGAINWaitReadable
        nil
      rescue EOFError
        break
      end
      s.render
      !live && break
    } rescue nil
    s.close
    ts.delete(Thread.current)
  }
}
