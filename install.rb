#!/usr/local/bin/ruby -w

# This program will take the files
#   compiler/ruby.vim
#   ftplugin/ruby.vim
#   indent/ruby.vim
#   syntax/ruby.vim
# and install them in a place where Vim can see them.  If the environment
# variable $VIM exists, it is assumed to point to, e.g. /usr/share/vim/vim62, so
# the files can be placed in $VIM/syntax, etc.  But it is unlikely that $VIM is
# defined, so this program will guess a few locations, using Unix and Windows
# sensibilities.  It will, in fact, default to the user's ~/.vim or
# $HOME/vimfiles.
#

USAGE = <<-EOF
Usage: ruby install.rb [options]

 Options:
   -g      install in global vim configuration directory
   -u      install in user's (i.e. your) vim configuration directory (default)
   -d DIR  install in DIR
   -i      confirm before doing anything, especially overwriting files
   -f      no confirmations
EOF

raise "Not implemented"
