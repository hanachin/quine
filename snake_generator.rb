C=File.read(__FILE__).split('AA'+'BB').last.gsub(/ +/, ' ').gsub(/^ +/, '').lines.map(&:chomp).reject {|s|
  s.start_with?('#')||s.empty?
}.join
puts C.size
# eval C
# exit
# def render
#   formatted = C wo asciiaato ni kuuhaku ireru
#   puts "eval C=%w(#{formatted}).join"
# end

# AABB
require'socket';

H,W,T,A=24,80,Thread,Array;
using Module.new{refine(A){define_method(:y){first};define_method(:x){last}}};
m,ts,fs=nil,[],[];
dm,bp,rt=
      {"\e[A"=>->y,x{[(y-1)%H,x]},"\e[B"=>->y,x{[(y+1)%H,x]},"\e[C"=>->y,x{[y,(x+1)%W]},"\e[D"=>->y,x{[y,(x-1)%W]}},
->{loop{x,y=rand(W),rand(H);return[y,x]if m[y][x]==' '}},
T.start{
  loop{
    nm=A.new(H){A.new(W){' '}};
    ts.each{|t|
      t.n;
      t.b.each{|y,x|nm[y][x]=t.p}
    };
    m=nm;
    ts.combination(2){@2.b.include?(@1.b.first)&&@1.e};
    fs.size<30&&fs<<bp.();
    fs.each{m[@1][@2]='@'};

    # koko
    ci=0
    m2=Array.new(H*N){Array.new(W*N){' '}}
    m.each_with_index{|r,y|
      r.each_with_index{|c,x|
        if c=='@';
          N.times{|yi|
            ci+=N;
            m2[y*N+yi][x..x+N]=C[ci-N..ci]
          }
        elsif c==' ';
          N.times{|yi|m2[y*N+yi][x...x+N]=' '*N};
        else;
          N.times{|yi|m2[y*N+yi][x...x+N]=(c*N)};
        end
      }
    }
    # "\x1b[48;5;%dm%03d\x1b[0m"%[@1,@1]
    m2.each_with_index{|r,y|
      # $stdout.print("\x1b[#{y+1};1H\x1b[K",*r)
    }
    # made

    sleep(0.1)
  }
};

p=?A;

gs=TCPServer.open(1234);

loop{
  ts<<T.start(gs.accept){|s|
    q,d,l,b,p=p,"",true,[bp.()],p.next;
    define_method(q*N){|*|};
    f=T.current.:define_singleton_method;
    f.(:p){q};
    f.(:d){d};
    f.(:e){l=false};
    f.(:b){b};
    f.(:n){
      nb=b.dup;
      h=nb.first;
      e=nb.pop;
      nh=dm[d]&.(*h)||h;
      nb.unshift(nh);
      fs.delete(nh)&&nb.push(e);
      b=nb;
    };
    s.print([255,253,34,255,250,34,1,0,255,240,255,251,1].pack('c*'),"\x1b[2J\x1b[?12l");
    loop{
      begin;
        d=s.read_nonblock(3);
      rescue IO::EAGAINWaitReadable;
      rescue;
        break;
      end;
      m.each_with_index{|r,y|s.print("\x1b[#{y+1};1H\x1b[K",*r)};
      l||break
    }rescue 1;
    s.close;
    ts.delete(T.current)
  }
}
