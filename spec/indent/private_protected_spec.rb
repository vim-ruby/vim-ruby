require 'spec_helper'

describe "Indenting" do
  specify "default public/private indenting" do
    assert_correct_indenting <<-EOF
      class One
        def two
        end

        protected

        def three
        end

        private

        def four
        end
      end
    EOF
  end

  specify "indented public/private" do
    vim.command 'let g:ruby_indent_private_protected_style = "indent"'

    assert_correct_indenting <<-EOF
      class One
        def two
        end

        protected

          def three
          end

        private

          def four
          end
      end
    EOF

    assert_correct_indenting <<-EOF
      class One
        def two
        end

        private :two
        protected :two

        def three
        end
      end
    EOF
  end
end
