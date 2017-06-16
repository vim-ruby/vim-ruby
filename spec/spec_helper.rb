require 'tempfile'
require 'vimrunner'
require 'vimrunner/rspec'
RSpec.configure do |config|
  config.around(:example) do |example|
    Tempfile.open("vim-ruby-vfile.txt") do |tmp|
      @messages = tmp.path
      example.run
      next unless example.exception

      warn tmp.read
    end
  end
end

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.prepend_runtimepath(File.expand_path('../..', __FILE__))
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
    vim.normal ":let g:ruby_indent_debug = 1\r"
    vim
  end

  def assert_correct_indenting(extension='rb', string)
    filename = "test.#{extension}"

    IO.write filename, string

    vim.edit filename
    vim.normal ":messages clear\r"
    vim.set 'vfile', @messages
    vim.normal ":12verbose normal gg=G\r"
    vim.set 'vfile'
    vim.write

    expect(IO.read(filename)).to eq string
  end
end
