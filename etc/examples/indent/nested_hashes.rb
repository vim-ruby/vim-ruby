class Foo
  var.func1(:param => 'value') do
    var.func2(:param => 'value') do
      puts "test"
    end
  end

  var.func1(:param => 'value') {
    var.func2(:param => 'value') {
      foo({ bar => baz })
      puts "test one"
      puts "test two"
    }
  }

  foo, bar = {
    :bar => {
      :one => 'two',
      :three => 'four',
      :five => 'six'
    }
  }

  var.
    func1(:param => 'value') {
      var.func2(:param => 'value') {
        puts "test"
      }
  }

  var.
    func1(:param => 'value') {
      func1_5(:param => 'value')
  var.func2(:param => 'value') {
    puts "test"
  }
  }

  foo,
    bar = {
      :bar => {
        :foo { 'bar' => 'baz' },
        :one => 'two',
        :three => 'four'
      }
  }
end
