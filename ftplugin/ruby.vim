" Vim filetype plugin
" Language:	Ruby
" Maintainer:	Gavin Sinclair <gsinclair at soyabean.com.au>
" Info:         $Id: ruby.vim,v 1.7 2004/01/10 23:06:11 gsinclair Exp $
" URL:          http://vim-ruby.sourceforge.net
" Anon CVS:     See above site 
" Licence:      GPL (http://www.gnu.org)
" Disclaimer: 
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------
"
" Matchit support thanks to Ned Konz.  See his ftplugin/ruby.vim at
"   http://bike-nomad.com/vim/ruby.vim.
" ----------------------------------------------------------------------------

" Only do this when not done yet for this buffer
if (exists("b:did_ftplugin"))
  finish
endif
let b:did_ftplugin = 1

" Matchit support
if exists("loaded_matchit") && !exists("b:match_words")
  let b:match_ignorecase = 0
  let b:match_words =
     \ '\%(\%(\%(^\|[;=]\)\s*\)\@<=\%(class\|module\|while\|begin\|until' .
     \ '\|for\|if\|unless\|def\|case\)\|\<do\)\>:' .
     \ '\<\%(else\|elsif\|ensure\|rescue\|when\)\>:' .
     \ '\%(^\|[^.]\)\@<=\<end\>'
endif

"
" Instructions for enabling "matchit" support:
"
" 1. Look for the latest "matchit" plugin at
"
"         http://www.vim.org/scripts/script.php?script_id=39
"
"    It is also packaged with Vim, in the $VIMRUNTIME/macros directory.
"
" 2. Copy "matchit.txt" into a "doc" directory (e.g. $HOME/.vim/doc).
"
" 3. Copy "matchit.vim" into a "plugin" directory (e.g. $HOME/.vim/plugin).
"
" 4. Ensure this file (ftplugin/ruby.vim) is installed.
"
" 5. Ensure you have this line in your $HOME/.vimrc:
"         filetype plugin on
"
" 6. Restart Vim and create the matchit documentation:
"
"         :helptags ~/.vim/doc
"
"    Now you can do ":help matchit", and you should be able to use "%" on Ruby
"    keywords.  Try ":echo b:match_words" to be sure.
"
" Thanks to Mark J. Reed for the instructions.  See ":help vimrc" for the
" locations of plugin directories, etc., as there are several options, and it
" differs on Windows.  Email gsinclair@soyabean.com.au if you need help.
"

" vim: sw=2 sts=2 ts=8 ff=unix:
