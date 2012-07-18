do
  something
end

def foo
  a_hash = {:do => 'bar'}
end

def foo(job)
  job.do!
end

proc do |(a, b)|
  puts a
  puts b
end

proc do |foo, (a, b), bar|
  puts a
  puts b
end

proc do |(a, (b, c)), d|
  puts a, b
  puts c, d
end

define_method "something" do |param|
  if param == 42
    do_something
  else
    do_something_else
  end
end

def foo
  opts.on('--coordinator host=HOST[,port=PORT]',
          'Specify the HOST and the PORT of the coordinator') do |str|
    h = sub_opts_to_hash(str)
    puts h
  end
end

module X
  Class.new do
  end
end
