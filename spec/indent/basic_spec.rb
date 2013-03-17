require 'spec_helper'

describe "Indenting" do
  specify "if-clauses" do
    assert_correct_indenting <<-EOF
      if foo
        bar
      end
    EOF

    assert_correct_indenting <<-EOF
      if foo
        bar
      else
        baz
      end
    EOF

    assert_correct_indenting <<-EOF
      bar if foo
      something_else
    EOF
  end
end
