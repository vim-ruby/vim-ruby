require 'spec_helper'

describe "Syntax highlighting" do
  # See issue #356
  specify "hashes with symbol keys and values on different lines" do
    assert_correct_highlighting <<~'EOF', 'x', 'rubySymbol'
      h = {
        x:
          really_long_method_name,
        y: 5,
      }
    EOF
  end

  # See issue #44
  specify "1.9 style hash keys with keyword names" do
    str = '{ class: "hello", if: "world", def: "i am", include: "foo", case: "bar", end: "baz" }'
    %w[class if def include case end].each do |p|
      assert_correct_highlighting str, p, 'rubySymbol'
    end

    assert_correct_highlighting <<~'EOF', 'end', 'rubyDefine'
      def hello
        { if: "world" }
      end
    EOF
  end

  # See issue #144
  specify "1.9 style hash keys with keyword names in parameter lists" do
    assert_correct_highlighting '{prepend: true}', 'prepend', 'rubySymbol'
    assert_correct_highlighting <<~'EOF', 'for', 'rubySymbol'
      Subscription.generate(for: topic,
                            to:  subscriber)
    EOF
  end

  # See issue #12
  specify "1.9 style hash keys with keyword names in argument lists" do
    str = <<~'EOS'
      validates_inclusion_of :gender, in: %w(male female), if: :gender_required?
    EOS
    [':\zsgender', 'in\ze:', 'if\ze:', ':\zsgender_required?'].each do |p|
      assert_correct_highlighting str, p, 'rubySymbol'
    end
  end
end
