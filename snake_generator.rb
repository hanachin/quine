C=File.read(__FILE__).split('AA'+'BB').last.gsub(/ +/, ' ').gsub(/^ +/, '')
puts C
# eval C
# exit

# AABB
require'socket'

H,W=24,80

# def render
#   formatted = C wo asciiaato ni kuuhaku ireru
#   puts "eval C=%w(#{formatted}).join"
# end

using Module.new{
  refine(Array){
    define_method(:y){first}
    define_method(:x){last}
  }
}

m,ts,fs=nil,[],[]

dm={"\e[A"=>->y,x{[(y-1)%H,x]},"\e[B"=>->y,x{[(y+1)%H,x]},"\e[C"=>->y,x{[y,(x+1)%W]},"\e[D"=>->y,x{[y,(x-1)%W]}}
bp=->{
  loop{
    x,y=rand(W),rand(H)
    return[y,x]if m[y][x]==' '
  }
}

rt=Thread.start{
  loop{
    nm=Array.new(H){Array.new(W){' '}}
    ts.each{|t|
      t.n
      t.b.each{|y,x|nm[y][x]=t.p}
    }
    m=nm
    ts.combination(2){@2.b.include?(@1.b.first)&&@1.e}
    fs.size<10&&fs<<bp.()
    fs.each{m[@1][@2]='@'}
    # ci = 0
    # m2 = Array.new(H*8) { Array.new(W*8) { ' ' } }
    # m.each_with_index { |r, y|
    #   r.each_with_index { |c, x|
    #     if c == '@'
    #       8.times { |yi|
    #         ci+=8
    #         m2[y*8+yi][x..x+8] = C[ci-8..ci]
    #       }
    #     elsif c == ' '
    #       8.times { |yi|
    #         m2[y*8+yi][x...x+8] = ' ' * 8
    #       }
    #     else
    #       8.times { |yi|
    #         m2[y*8+yi][x...x+8] = (c * 6).inspect
    #       }
    #     end
    #   }
    # }

    # m.each_with_index { |r, y|
    #   s.print("\x1b[#{y+1};1H\x1b[K",*r)
    # }
    # m2.each_with_index { |r,y|
    #   $stdout.print("\x1b[#{y+1};1H\x1b[K",*r)
    # }

    sleep(0.1)
  }
}

p=?A

gs=TCPServer.open(1234)

loop{
  ts<<Thread.start(gs.accept){|s|
    q,d,l,b,p=p,"",true,[bp.()],p.next

    fn=Thread.current.:define_singleton_method
    fn.(:p){q}
    fn.(:d){d}
    fn.(:e){l=false}
    fn.(:b){b}
    fn.(:n){
      nb=b.dup
      h=nb.first
      e=nb.pop
      nh=dm[d]&.(*h)||h
      nb.unshift(nh)
      fs.delete(nh)&&nb.push(e)
      b=nb
    }

    s.print([255,253,34,255,250,34,1,0,255,240,255,251,1].pack('c*'),"\x1b[2J\x1b[?12l")

    begin
      sleep(0.1)
      s.read_nonblock(999)
    rescue IO::EAGAINWaitReadable
      retry
    end

    loop{
      begin
        d=s.read_nonblock(3)
      rescue IO::EAGAINWaitReadable
      rescue
        break
      end

      m.each_with_index{|r,y|s.print("\x1b[#{y+1};1H\x1b[K",*r)}
      l||break
    }rescue 1
    s.close
    ts.delete(Thread.current)
  }
}
