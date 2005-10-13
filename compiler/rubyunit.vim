" Vim compiler file
" Language:	Test::Unit - Ruby Unit Testing Framework
" Maintainer:	Doug Kearns <djkea2 at gus.gscit.monash.edu.au>
" Info:		$Id: rubyunit.vim,v 1.10 2005/10/13 16:41:44 dkearns Exp $
" URL:		http://vim-ruby.rubyforge.org
" Anon CVS:	See above site
" Licence:	GPL (http://www.gnu.org)
" Disclaimer:
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------

if exists("current_compiler")
  finish
endif
let current_compiler = "rubyunit"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

CompilerSet makeprg=testrb

CompilerSet errorformat=\%W\ %\\+%\\d%\\+)\ Failure:,
			\%C%m\ [%f:%l]:,
			\%E\ %\\+%\\d%\\+)\ Error:,
			\%C%m:,
			\%C\ \ \ \ %f:%l:%.%#,
			\%C%m,
			\%Z\ %#,
			\%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: nowrap sw=2 sts=2 ts=8 ff=unix:
