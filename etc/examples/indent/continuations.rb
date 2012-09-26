# See https://github.com/vim-ruby/vim-ruby/issues/75 for details
puts %{#{}}
puts "OK"

while true
  begin
    puts %{#{x}}
  rescue ArgumentError
  end
end

variable =
  if condition?
    1
  else
    2
  end

variable = # evil comment
  case something
  when 'something'
    something_else
  else
    other
  end

array = [
  :one,
].each do |x|
  puts x.to_s
end
