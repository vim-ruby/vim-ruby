# See https://github.com/vim-ruby/vim-ruby/issues/75 for details
puts %{#{}}
puts "OK"

while true
  begin
    puts %{#{x}}
  rescue ArgumentError
  end
end
