#!/usr/local/bin/ruby -w
#
# Script to install the vim files in a useful directory.
#
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
# ------------------------------------------------------------------------------
#
# Revision: $Id: install.rb,v 1.4 2003/09/19 11:39:10 dkearns Exp $
# Status: alpha
#
# This was contributed by Hugh Sasse and is *UNTESTED*.  Usual disclaimers apply.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# ------------------------------------------------------------------------------
#
# Known issues (summarised by Hugh):
#   Only checks the places I could think of at the time.
#   Doesn't bother to preserve the old files in any way.
#   Doesn't ask the user if none of the directories apply, but that
#       would make it interactive.
#   Should it say "Job Done" or something? Silent success is a unix
#       idiom, but not so on Win*.
#   Doesn't check the files are in the correct format: no ^Ms for
#       unix...
#   Hasn't a clue what to do about Data Forks and .... thingy forks
#       on the mac.:-) Is there Ruby for pre OS-X Macs?
#
# Gavin's notes:
#   Doesn't include any Windows paths.  Should detect OS.
#   TODO: revision 1.1 described some handy CLI-options which could
#       be worked into here (e.g. global vs user directory).
#   TODO: improve banner at the top with some of the nice doco from
#       revision 1.1
#
# ------------------------------------------------------------------------------
#

require "ftools"

#
# This USAGE string does not apply to the current implementation, but it is a
# good guide for future work.
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

PREFIXSTUB=["/usr/local/share/vim",
        "/usr/local/vim",
        "/usr/share/vim",
        "/usr/vim",
        "/opt/share/vim",
        "/opt/vim"]

stub = PREFIXSTUB.detect { |x| File.exist?(x) and File.directory?(x) }

prefix = Dir.glob("#{stub}/vim*").sort[-1]

f = "ruby.vim"

pairs = [
    ["./compiler/#{f}", "#{prefix}/compiler/#{f}"],
    ["./ftplugin/#{f}", "#{prefix}/ftplugin/#{f}"],
    ["./indent/#{f}", "#{prefix}/indent/#{f}"],
    ["./syntax/#{f}", "#{prefix}/syntax/#{f}"],
]

pairs.each do |from, to|
    unless File.compare(from, to)
        # If it is the same don't bother copying.
        if File.exist?(to) and File.mtime(to) > File.mtime(from)
            # If the file to replace is newer, it could be someone's interim
            # patch, We assume they want to keep it, unless this is
            # called with -f. Warn about not doing so otherwise.
            if ARGV.include?("-f")
                File.install(from, to)
            else
                $stderr.puts "#{to} is newer than #{from}. `#{$0} -f` to force replacement"
            end
        else
            File.install(from, to)
        end
    end
end
