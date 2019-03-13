require 'spec_helper'

describe "Syntax highlighting" do
  specify "single line comments" do
    assert_correct_highlighting(<<~'EOF', '#.*', 'rubyComment')
      # comment line
    EOF
  end

  specify "end of line comments" do
    assert_correct_highlighting(<<~'EOF', '#.*', 'rubyComment')
      foo = 42 # comment
    EOF
  end

  specify "multiline comments" do
    str = <<~'EOF'
      # comment line 1
      # comment line 2
    EOF
    assert_correct_highlighting(str, '#.*line 1', 'rubyComment')
    assert_correct_highlighting(str, '#.*line 2', 'rubyComment')
  end

  specify "embedded documentation" do
    assert_correct_highlighting(<<~'EOF', 'documentation.*', 'rubyDocumentation')
      =begin
        documentation line
      =end
    EOF
    # See issue #3
    assert_correct_highlighting(<<~'EOF', 'documentation.*', 'rubyDocumentation')
      =begin rdoc
        documentation line
      =end rdoc
    EOF
  end

  specify "magic comments" do
    assert_correct_highlighting(<<~'EOF', 'frozen_string_literal', 'rubyMagicComment')
      # frozen_string_literal: true
    EOF
  end

  specify "TODO comments" do
    assert_correct_highlighting(<<~'EOF', 'TODO', 'rubyTodo')
      # TODO: turn off the oven
    EOF
  end

  specify "shebang comments" do
    assert_correct_highlighting(<<~'EOF', '#.*', 'rubySharpBang')
      #!/bin/ruby
    EOF
  end
end
