
require 'fileutils'
require 'pathname'

TGZ_DIR = 'build/pkg/tgz'
ZIP_DIR = 'build/pkg/zip'
RELEASE_FILES = FileList[
  'README', 'ChangeLog', 'install.rb',
  '{compiler,filetype,ftplugin,indent,syntax}/*.vim'
]

desc 'Create a ZIP file with \r\n line endings'
task :zip do
  zipfile = "vim-ruby-#{Date.today}.zip"
  prepare_directory(ZIP_DIR) do |path|
    system "u2d -D #{path}"
  end
  Dir.chdir(ZIP_DIR) do
    system "zip -r ../#{zipfile} ."
  end
  #FileUtils.rm_rf ZIP_DIR
end

desc 'Create a TGZ file with \n line endings'
task :tgz do
  tgzfile = "vim-ruby-#{Date.today}.tgz"
  prepare_directory(TGZ_DIR) do |path|
    system "d2u -U #{path}"
  end
  system "chmod -R 644 #{TGZ_DIR}"
  Dir.chdir(TGZ_DIR) do
    system "tar zcvf ../#{tgzfile} ."
  end
  #FileUtils.rm_rf TGZ_DIR
end


# Supporting methods

  #
  # Copies a whole path to the given directory.  For example
  # 
  #   copy_path('./compiler/ruby.vim', 'build/pkg/tgz')
  #
  # will create the file 'build/pkg/tgz/compiler/ruby.vim', creating any
  # directories it needs to on the way.
  #
  # Since the entire _path_ is used in determining the target path (which is _dir_
  # + _path_), you'd better be in the base directory of the files you're copying
  # before you call this.
  #
  # The path to the copied file is returned (Pathname).
  #
def copy_path(path, dir)
  path, dir = Pathname.new(path), Pathname.new(dir)
  target_path = dir.join(path)
  unless target_path.dirname.exist?
    target_path.dirname.mkpath
  end
  FileUtils.cp(path.to_s, target_path.to_s)
  target_path
end

  #
  # Copy all vim-ruby files for release into the given directory (creating it first
  # if necessary).  The full path to each newly-created file is yielded, allowing
  # transformations such as line endings and permissions.
  #
def prepare_directory(dir)  # :yield: path
  raise "Inappropriate directory" unless [TGZ_DIR, ZIP_DIR].include? dir
  FileUtils.rm_rf dir
  FileUtils.mkpath dir
  RELEASE_FILES.each do |path|
    newpath = copy_path path, dir
    yield newpath
  end
end
