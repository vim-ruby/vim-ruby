" Vim indent file
" Language:	Ruby
" Maintainer:	Gavin Sinclair <gsinclair@soyabean.com.au>
" Last Change:	2003 May 11
" URL: www.soyabean.com.au/gavin/vim/index.html
" Changes: (since vim 6.1)
"  - indentation after a line ending in comma, etc, (even in a comment) was
"    broken, now fixed (2002/08/14)
" TODO: need to indent one level on [

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetRubyIndent()
setlocal nolisp
setlocal nosmartindent
setlocal autoindent
setlocal indentkeys+==end,=else,=elsif,=when,=ensure,=rescue,0),==begin,==end

" Only define the function once.
if exists("*GetRubyIndent")
  finish
endif

function s:IsInStringOrComment(line, col)
  return synIDattr(synID(a:line, a:col, 0), 'name') =~? 'string\|comment'
endfunction

let g:ruby_indent_keywords = 'module,class,def,if,for,while,until,else,elsif,'.
      \'case,when,unless,begin,ensure,rescue'

function s:BuildIndentKeywords()
  let idx = stridx(g:ruby_indent_keywords, ',')
  while idx > -1
    let keyword = strpart(g:ruby_indent_keywords, 0, idx).'\>'
    if exists('s:ruby_indent_keywords')
      let s:ruby_indent_keywords = s:ruby_indent_keywords.'\|'.keyword
    else
      let s:ruby_indent_keywords = "\\(".keyword
    endif
    let g:ruby_indent_keywords = strpart(g:ruby_indent_keywords, idx + 1)
    let idx = stridx(g:ruby_indent_keywords, ',')
  endwhile

  if exists('s:ruby_indent_keywords')
    let s:ruby_indent_keywords = s:ruby_indent_keywords.'\|'.
	  \g:ruby_indent_keywords.'\>\)'
  else
    let s:ruby_indent_keywords = g:ruby_indent_keywords.'\>'
  endif
endfunction
call s:BuildIndentKeywords()

let s:continuation_regexp = '[*+/.-]\s*\(#.*\)\=$'
let s:block_regexp = '\({\|\<do\>\)\s*\(|\(\h\w*\(,\s*\)\=\)\+|\s*\)\=\(#.*\)\=$'
let s:skip_expr = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"'


" FIXME: with a little reorginization (using returns instead of let ind =
" ...), we could speed things up a bit
function GetRubyIndent()
  " Set up variables for restoring position in file.  Could use v:lnum here.
  let clnum = line('.')
  let ccol = col('.')

  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  let line = getline(lnum)
  let ind = indent(lnum)
  let did_indent = 0
  let did_end_indent = 0

  " If the previous line ended with [*+/.-], indent one extra level.
  let col = match(line, s:continuation_regexp) + 1
  if col > 0 && !s:IsInStringOrComment(lnum, col)
    let ind + &sw
    let did_indent = 1
  endif

  " If the previous line ended in a parentheses, get the indent of the line
  " that opened it.
  let col = matchend(line, '^\s*)') + 1
  if !did_indent && col > 0
    execute 'normal '.lnum.'G'.col.'|'
    if searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = indent('.')
      let did_indent = 1
    endif
    execute 'normal '.clnum.'G'.ccol.'|'
  endif

  " If the previous line ended with an indenting keyword, add one level.
  let col = match(line,  '^\s*'.s:ruby_indent_keywords) + 1
  if !did_indent && col > 0 || line =~ s:block_regexp
    let ind = ind + &sw
    let did_indent = 1
    let did_end_indent = 1
  endif

  " Otherwise, check if the previous line was a continuation line.
  if !did_indent
    let my_lnum = prevnonblank(lnum - 1)
    if my_lnum > 0
      let my_line = getline(my_lnum)
      let my_ind = indent(my_lnum)

      if my_line =~ s:continuation_regexp
	let col = match(my_line, s:continuation_regexp) + 1
	if col > 0 && !s:IsInStringOrComment(my_lnum, col)
	  let ind = my_ind
	  let did_indent = 1
	endif
      endif
    endif
  endif

  " If we indented and the line ended with an 'end', decrese indent.
  " TODO: make this more intelligent (check with searchpair())
  if did_indent && line =~ '\<end\>\s*\(#.*\)\=$'
    let ind = ind - &sw
  endif

  " Get the current line.
  let line = getline(v:lnum)

  " If we are inside a pair of braces, well at least after an opening one.
  if 0 < searchpair('(', '', ')', 'bW', s:skip_expr)
    let ind = virtcol('.')
    execute 'normal '.clnum.'G'.ccol.'|'
  endif

  " Deindent on a closing ) on an empty line.
  let col = matchend(line, '^\s*)') + 1
  if col > 0
    execute 'normal '.col.'|'
    if searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = virtcol('.') - 1
    endif
    execute 'normal '.ccol.'|'
  endif


  " If we got a brace on an empty line, find match and indent to its level.
  let col = matchend(line, '^\s*}') + 1
  if col > 0
    execute 'normal '.col.'|'
    if searchpair('{', '', '}', 'bW', s:skip_expr) > 0
      let ind = indent('.')
    endif
    execute 'normal '.ccol.'|'
  endif

  " If we got an 'end' on an empty line, find match and indent to its level.
  let col = matchend(line,
	\'^\s*\(rescue\>\|else\>\|ensure\>\|end\>\|when\>\)') + 1
  if col > 0
    execute 'normal '.col.'|'
    "\<ensure\>\|\<else\>\|\<rescue\>\|\<elsif\>\|\<when\>
    if searchpair('\<def\>\|\<do\>\|\<if\>\|\<unless\>\|\<case\>\|\<begin\>\|\<until\>\|\<for\>\|\<while\>\|\<class\>\|\<module\>', 
	  \'\<ensure\>\|\<else\>\|\<rescue\>\|\<elsif\>\|\<when\>', '\<end\>',
	  \'bW', s:skip_expr) > 0
      let ind = indent('.')
    endif
    execute 'normal '.clnum.'G'.ccol.'|'
  endif

  return ind
endfunction

" vim:sw=2

