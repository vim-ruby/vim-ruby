require 'spec_helper'

describe "Indenting" do
  specify "heredoc strings are left as-is" do
    # See https://github.com/vim-ruby/vim-ruby/issues/318 for details
    assert_correct_indenting <<-EOF
      def foo
        <<-EOS
          one
            \#{two} three
              four
        EOS
      end
    EOF
  end
end
