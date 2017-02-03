require 'vimrunner'
require 'vimrunner/rspec'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.prepend_runtimepath(File.expand_path('../..', __FILE__))
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
    vim
  end

  def assert_correct_indenting(extension='rb', string)
    whitespace = string.scan(/^\s*/).first
    string = string.split("\n").map { |line| line.gsub /^#{whitespace}/, '' }.join("\n").strip

    filename = "test.#{extension}"

    File.open filename, 'w' do |f|
      f.write string
    end

    vim.edit filename
    vim.normal 'gg=G'
    vim.write

    IO.read(filename).strip.should eq string
  end
end
