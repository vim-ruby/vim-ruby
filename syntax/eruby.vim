" Vim syntax file
" Language:		eRuby
" Maintainer:		Doug Kearns <dougkearns@gmail.com>
" Info:			$Id$
" URL:			http://vim-ruby.rubyforge.org
" Anon CVS:		See above site
" Release Coordinator:	Doug Kearns <dougkearns@gmail.com>

if exists("b:current_syntax")
    finish
endif

if !exists("main_syntax")
  let main_syntax = 'eruby'
endif

if version < 600
  so <sfile>:p:h/html.vim
  syn include @rubyTop <sfile>:p:h/ruby.vim
else
  runtime! syntax/html.vim
  unlet b:current_syntax
  syn include @rubyTop syntax/ruby.vim
endif

syn cluster erubyRegions contains=erubyOneLiner,erubyBlock,erubyExpression,erubyComment

syn region  erubyOneLiner   matchgroup=erubyDelimiter start="^%%\@!"	end="$"     contains=@rubyTop	     containedin=ALLBUT,@erubyRegions keepend oneline
syn region  erubyBlock	    matchgroup=erubyDelimiter start="<%%\@!-\=" end="-\=%>" contains=@rubyTop	     containedin=ALLBUT,@erubyRegions
syn region  erubyExpression matchgroup=erubyDelimiter start="<%="	end="-\=%>" contains=@rubyTop	     containedin=ALLBUT,@erubyRegions
syn region  erubyComment    matchgroup=erubyDelimiter start="<%#"	end="-\=%>" contains=rubyTodo,@Spell containedin=ALLBUT,@erubyRegions keepend

hi def link erubyDelimiter	Delimiter
hi def link erubyComment	Comment

let b:current_syntax = "eruby"

if main_syntax == 'eruby'
  unlet main_syntax
endif

" vim: nowrap sw=2 sts=2 ts=8 ff=unix:
