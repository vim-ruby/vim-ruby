require 'spec_helper'

describe "Syntax highlighting" do
  before :each do
    vim.command 'let g:ruby_operators = 1'
  end
  after :each do
    vim.command 'unlet g:ruby_operators'
  end

  specify "modulo-assignment operators" do
    assert_correct_highlighting <<~'EOF', '%=', 'rubyAssignmentOperator'
      foo %= bar
    EOF
  end

  specify "ternary operators" do
    str = <<~'EOF'
      foo = bar ? 4 : 2
    EOF
    assert_correct_highlighting str, '?', 'rubyTernaryOperator'
    assert_correct_highlighting str, ':', 'rubyTernaryOperator'
  end

  context "bracket operators" do
    specify "after a plain identifier" do
      assert_correct_highlighting <<~'EOF', '\\[..]', 'rubyOperator'
        foo[42]
      EOF
    end
    specify "after a ?!-named bare method call" do
      assert_correct_highlighting <<~'EOF', '\\[..]', 'rubyOperator'
        foo?[42]
      EOF
    end
    specify "after a closing parenthesis" do
      assert_correct_highlighting <<~'EOF', '\\[..]', 'rubyOperator'
        (foo)[42]
      EOF
    end
    specify "after a literal hash" do
      assert_correct_highlighting <<~'EOF', '\\[...]', 'rubyOperator'
        { foo: bar }[foo]
      EOF
    end
    specify "after a block arg method call" do
      assert_correct_highlighting <<~'EOF', '\\[..]', 'rubyOperator'
        foo { bar }[42]
      EOF
    end
  end

  specify "exponentiation operators" do
    [
      'foo**bar',
      'foo ** bar',
      'foo** bar',
    ].each do |p|
      assert_correct_highlighting p, '\*\*', 'rubyArithmeticOperator'
    end
  end

  context "double splat operators" do
    specify "in method definitions" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        def foo(**bar)
        end
      EOF
    end
    specify "in multiline parameter list method definitions" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        def foo(bar,
                **baz)
        end
      EOF
    end
    specify "as an anonymous parameter in method definitions" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        def foo(**)
        end
      EOF
    end
    specify "in unparenthesised method definitions" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        def foo **bar
        end
      EOF
    end
    specify "in unparenthesised method calls" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        foo **bar
      EOF
    end
    specify "in block parameter lists" do
      assert_correct_highlighting <<~'EOF', '\*\*', 'rubyDoubleSplatOperator'
        foo { |**bar| 42 }
      EOF
    end
  end

  specify "multiplication operators" do
    [
      'foo*bar',
      'foo * bar',
      'foo* bar',
    ].each do |p|
      assert_correct_highlighting p, '\*', 'rubyArithmeticOperator'
    end
  end

  context "splat operators" do
    specify "in method definitions" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        def foo(*bar)
        end
      EOF
    end
    specify "in multiline parameter list method definitions" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        def foo(bar,
                *baz)
        end
      EOF
    end
    specify "as an anonymous parameter in method definitions" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        def foo(*)
        end
      EOF
    end
    specify "in unparenthesised method definitions" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        def foo *bar
        end
      EOF
    end
    specify "in unparenthesised method calls" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        foo *bar
      EOF
    end
    specify "in block parameter lists" do
      assert_correct_highlighting <<~'EOF', '\*', 'rubySplatOperator'
        foo { |*bar| 42 }
      EOF
    end
  end

  context "proc operators" do
    specify "in method definitions" do
      assert_correct_highlighting <<~'EOF', '&', 'rubyProcOperator'
        def foo(&bar)
        end
      EOF
    end
    specify "in multiline parameter list method definitions" do
      assert_correct_highlighting <<~'EOF', '&', 'rubyProcOperator'
        def foo(bar,
                &baz)
        end
      EOF
    end
    specify "in unparenthesised method definitions" do
        assert_correct_highlighting <<~'EOF', '&', 'rubyProcOperator'
          def foo &bar
          end
        EOF
    end
    specify "in unparenthesised method calls" do
        assert_correct_highlighting <<~'EOF', '&', 'rubyProcOperator'
            foo &bar
        EOF
    end
    specify "before literal lambdas" do
        assert_correct_highlighting <<~'EOF', '&', 'rubyProcOperator'
            foo &->{}
        EOF
    end
  end

  specify "eigenclass operators" do
      assert_correct_highlighting <<~'EOF', '<<', 'rubyEigenClassOperator'
        class << self
        end
      EOF
  end

  specify "superclass operators" do
      assert_correct_highlighting <<~'EOF', '<', 'rubySuperClassOperator'
        class Foo < Bar
        end
      EOF
  end
end
