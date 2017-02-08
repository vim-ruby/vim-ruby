require 'spec_helper'

describe "Indenting" do
  specify "method definitions prefixed with access modifiers" do
    assert_correct_indenting <<~EOF
      class Foo
        public def one(x)
        end

        private def two(y)
          code
        end
      end
    EOF
  end
end
