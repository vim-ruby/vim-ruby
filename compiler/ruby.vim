" Vim compiler file
" Language:	Ruby
" Function:	Syntax check and/or error reporting
" Maintainer:	Tim Hammerquist <timh at rubyforge.org>
" Info:		$Id: ruby.vim,v 1.6 2003/09/03 03:46:52 dkearns Exp $
" URL:		http://vim-ruby.rubyforge.org
" Anon CVS:	See above site
" Licence:	GPL (http://www.gnu.org)
" Disclaimer:
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------
"
" Changelog:
" 0.2:  script saves and restores 'cpoptions' value to prevent problems with
"       line continuations
" 0.1:  initial release
"
" Contributors:
"   Hugh Sasse <hgs@dmu.ac.uk>
"   Doug Kearns <djkea2@mugca.its.monash.edu.au>
"
" Todo:
"   match error type %m
"
" Comments:
"   I know this file isn't perfect.  If you have any questions, suggestions,
"   patches, etc., please don't hesitate to let me know.
"
"   This is my first experience with 'errorformat' and compiler plugins and
"   I welcome any input from more experienced (or clearer-thinking)
"   individuals.
" ----------------------------------------------------------------------------

if exists("current_compiler")
  finish
endif
let current_compiler = "ruby"

let s:cpo_save = &cpo
set cpo-=C

" default settings runs script normally
" add '-c' switch to run syntax check only:
"
"   setlocal makeprg=ruby\ -wc\ $*
"
" or add '-c' at :make command line:
"
"   :make -c %<CR>
"
setlocal makeprg=ruby\ -w\ $*

setlocal errorformat=
    \%+E%f:%l:\ parse\ error,
    \%W%f:%l:\ warning:\ %m,
    \%E%f:%l:in\ %*[^:]:\ %m,
    \%E%f:%l:\ %m,
    \%-C%\tfrom\ %f:%l:in\ %.%#,
    \%-Z%\tfrom\ %f:%l,
    \%-Z%p^,
    \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ft=vim ff=unix
