$c=File.read(__FILE__).split('AA'+'BB').last.gsub(/ +/, ' ').gsub(/^ +/, '').lines.map(&:chomp).reject {|s|
  s.start_with?('#')||s.empty?
}.join
# eval C
# exit
# def render
#   formatted = C wo asciiaato ni kuuhaku ireru
#   puts "eval C=%w(#{formatted}).join"
# end


# AABB
require'socket';


$c="eval($c=%w(#{$c}).join)";
# [[280,8],[357,5],[364,3],[369,1],[436,15],[492,1],[515,5],[591,19],[667,9],[746,6],[826,7],[907,19],[991,20],[1085,11],[1169,7],[1242,12],[1308,20],[1380,12],[1513,1]]
# [[360,8],[437,4],[444,2],[449,1],[516,15],[572,1],[595,5],[671,19],[747,9],[826,6],[906,7],[987,16],[1071,20],[1163,10],[1220,4],[1249,5],[1303,5],[1322,10],[1388,16],[1593,1]]
# [[440,8],[517,4],[524,2],[529,1],[596,15],[675,5],[751,19],[827,9],[906,6],[986,7],[1067,16],[1151,20],[1243,10],[1300,4],[1329,5],[1383,5],[1402,10],[1468,16],[1673,1]]
    # [[440,8],[517,4],[524,2],[529,1],[596,15],[652,1],[675,5],[751,19],[827,9],[906,6],[986,7],[1067,16],[1151,20],[1243,10],[1300,4],[1329,5],[1383,5],[1402,10],[1468,16],[1673,1]]
    # [[357,6],[436,8],[515,11],[593,4],[601,7],[672,4],[679,1],[681,1],[683,6],[752,4],[760,2],[763,7],[831,3],[840,1],[842,8],[911,7],[919,1],[921,9],[991,7],[999,1],[1005,5],[1072,7],[1086,4],[1153,16],[1235,13],[1673,1]]
[[436,6],[515,10],[593,4],[601,5],[672,4],[679,1],[681,1],[683,4],[752,4],[760,2],[763,5],[831,3],[840,1],[842,7],[911,7],[919,1],[921,8],[991,7],[999,1],[1005,4],[1072,7],[1086,3],[1153,15],[1235,11],[1673,1]]
  .each{$c[@1,0]=0x20.chr*@2};

H,W,T,A=24,80,Thread,Array;
using(Module.new{refine(A){define_method(:y){first};define_method(:x){last}}});
m,ts,fs=nil,[],[];
print("\x1b[2J");
dm,bp,rt=
      {"\e[A"=>->y,x{[(y-1)%H,x]},"\e[B"=>->y,x{[(y+1)%H,x]},"\e[C"=>->y,x{[y,(x+1)%W]},"\e[D"=>->y,x{[y,(x-1)%W]}},
->{loop{x,y=rand(W),rand(H);unless(m[y][x].start_with?("\x1b"));return[y,x];end}},
T.start{
  loop{
    nm=A.new(H){A.new(W){' '}};
    i=0;
    nm.each_with_index{|r,y|
      r.each_with_index{|c,x|
        nm[y][x]=$c[i]||'#';i+=1
      }
    };
    tts=ts.select{|t|t.respond_to?(:n)};
    tts.each{|t|
      t.n;
      t.b.each{|y,x|nm[y][x]="\x1b[48;5;%dm%s\x1b[0m"%[t.p,nm[y][x]]}
    };
    m=nm;
    tts.combination(2){@2.b.include?(@1.b.first)&&@1.e;@1.b.include?(@2.b.first)&&@2.e};
    fs.size<5&&fs<<bp.();
    fs.each{m[@1][@2]="\x1b[48;5;0m%s\x1b[0m"%m[@1][@2]};
    $stdout.print(m.map.with_index{|r,y|"\x1b[#{y+1};1H\x1b[K"+r.join}.join);
    sleep(0.1)
  }
};

p=0;

gs=TCPServer.open(1234);
begin;
loop{
  ts<<T.start(gs.accept){|s|
    q,d,l,b=(p=p.next),"",true,[bp.()];
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
      rescue(IO::EAGAINWaitReadable);
      rescue;
        break;
      end;
      s.print(m.map.with_index{|r,y|"\x1b[#{y+1};1H\x1b[K"+r.join}.join);
      l||break
    }rescue(1);
    s.close;
    ts.delete(T.current)
  }
};
rescue(Interrupt);
end
