aa =File.read('foo.rb')
white_spaces = aa.gsub("\n","").chars.chunk {|x| x == " " }.map { @2.size }.each_slice(2).to_a
white_spaces.pop
print "[",white_spaces.inject([]) {
  if prev = @1.last
    @1 << [@2.first+prev.sum, @2.last]
  else
    [[@2.first+240,@2.last]]
  end
}.map { "[#{@1},#{@2}]" }.join(","),"]\n"
