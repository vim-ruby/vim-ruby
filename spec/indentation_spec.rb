require 'tempfile'
require 'open3'

# Each spec here contains an example of correctly-indented code. When the
# expect_indent method runs Vim, it dedents all of the code then reindents it.
# It passes only if it matches the correcty-indented code that the spec
# originally gave it.

describe "indentation" do
  it "indents nested definitions" do
    expect_indent %{
module Foo
  class Bar
    def baz
    end
  end
end
    }
  end

  it "indents continued arrays" do
    expect_indent %{
foo = [one,
       two,
       three]
    }
  end

  it "indents splat arguments inside square brackets" do
    expect_indent %{
Hash[*
  items.each do
    something
  end
]
    }
  end

  it "indents splat arguments inside calls to capitalized methods" do
    expect_indent %{
x = Foo(*y do
  z
end)
    }

    expect_indent %{
x = Foo(
  *y do
    z
  end
)
    }
  end

  it "indents mult-line arguments, one argument per line" do
    expect_indent %{
User.new(
  :first_name => 'Andrew',
  :last_name => 'Radev'
)
    }
  end

  it "indents arguments where the first is on the same line as the method" do
    expect_indent %{
User.new(:first_name => 'Andrew',
         :last_name => 'Radev')
    }
  end
end

describe "expect_indent", "meta-test" do
  it "fails when the string isn't indented exactly as given" do
    expect do
      expect_indent %{
def f
this_is_not_indented_correctly
end
      }
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it "succeeds when the string is indented as given" do
    expect_indent %{
def f
  this_is_indented_correctly
end
    }
  end
end

def expect_indent(code)
  code = code.strip + "\n" # Normalize leading/trailing whitespace
  output_file = Tempfile.new("vim_ruby_indent_test")
  begin
    indent_code_into_file(code, output_file)
    output_file.rewind
    output_file.read.should == code
  ensure
    output_file.close
    output_file.unlink
  end
end

def indent_code_into_file(code, output_file)
  command = vim_indent_command(output_file.path)
  IO.popen(command, "w") do |io|
    io.write(code)
  end
end

def vim_indent_command(output_path)
  [
    "vim",
    "--noplugin -u /dev/null", # No plugins, no vimrc
    "-c ':source ftplugin/ruby.vim'", # Load Ruby file type
    "-c ':source indent/ruby.vim'", # Load indent
    "-c ':set sw=2'", # Force indentation width
    "-c ':set expandtab'", # Tabs are morally reprehensible.
    "-c ':set ft=ruby'", # Force to Ruby file type
    "-c ':%s/^ \\+//g'", # Delete all leading whitespace
    "-c ':normal 1G=G'", # Reindent the code
    "-c ':w! #{output_path}'", # Write the reindented code to the pipe
    "-c ':q!'", # Quit
    "-", # Operate on stdin
  ].join(" ")
end

