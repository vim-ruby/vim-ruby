require 'rubygems'
require 'rake/gempackagetask'

PACKAGE_NAME = 'vim-ruby'
RELEASE_FILES = FileList[
  'README', 'ChangeLog', 'bin/*.rb',
  '{compiler,ftdetect,ftplugin,indent,syntax}/*.vim'
]
PACKAGE_VERSION = Time.now.strftime('%Y.%m.%d')

desc "Build all the packages"
task :default => :package


def gemspec
  Gem::Specification.new do |s|
    s.name                  = PACKAGE_NAME
    s.version               = PACKAGE_VERSION
    s.files                 = RELEASE_FILES.to_a
    s.summary               = "Ruby configuration files for Vim.  Run 'vim-ruby-install.rb' to complete installation."
    s.description           = s.summary + "\n\nThis package doesn't contain a Ruby library."
    s.requirements          << 'RubyGems 0.8+' << 'Vim 6.0+'
    s.required_ruby_version = '>= 1.8.0'
    s.require_path          = '.'
    s.bindir                = 'bin'
    s.executables           = ['vim-ruby-install.rb']
    s.author                = 'Gavin Sinclair et al.'
    s.email                 = 'gsinclair@soyabean.com.au'
    s.homepage              = 'http://vim-ruby.rubyforge.org'
    s.rubyforge_project     = 'vim-ruby'
    s.has_rdoc              = false
  end
end

Rake::GemPackageTask.new(gemspec) do |t|
  t.package_dir = 'etc/package'
  t.need_tar = true
end

# Supporting methods

# vim: ft=ruby
