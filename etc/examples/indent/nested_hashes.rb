class Foo
  # nested do ... end blocks:
  var.func1(:param => 'value') do
    var.func2(:param => 'value') do
      puts "test"
    end
  end

  # nested { ... } blocks
  var.func1(:param => 'value') {
    var.func2(:param => 'value') {
      foo({ bar => baz })
      puts "test one"
      puts "test two"
    }
  }

  # nested hash
  foo, bar = {
    :bar => {
      :one => 'two',
      :five => 'six'
    }
  }

  # nested { ... } blocks with a continued first line
  var.
    func1(:param => 'value') {
    var.func2(:param => 'value') {
      puts "test"
    }
  }

  # nested hashes with a continued first line
  foo,
    bar = {
    :bar => {
      :foo { 'bar' => 'baz' },
      :one => 'two',
      :three => 'four'
    }
  }

  # TODO nested { ... } blocks with a continued first line and a function call
  # inbetween
  var.
    func1(:param => 'value') {
    func1_5(:param => 'value')
  var.func2(:param => 'value') {
    puts "test"
  }
  }
end
