" Vim indent file
" Language:	Ruby
" Maintainer:	Gavin Sinclair <gsinclair at soyabean.com.au>
" Developer:	Nikolai Weibull <lone-star at home.se>
" Info:		$Id$
" URL:		http://vim-ruby.rubyforge.org/
" Anon CVS:	See above site
" Licence:	GPL (http://www.gnu.org/)
" Disclaimer:
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------

" 0. Initialization {{{1
" =================

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e
setlocal indentkeys+==end,=elsif,=when,=ensure,=rescue,==begin,==end

" Only define the function once.
if exists("*GetRubyIndent")
  finish
endif

" 1. Variables {{{1
" ============

" Items in this regex are syntax groups that delimit strings or comments.
let s:skip_regex = '\<ruby\%(String\|StringDelimiter\|ASCIICode' .
      \ '\|Interpolation\|NoInterpolation\|Escape\|Comment\|Documentation\)\>'

" Items in this regex are syntax groups that delimit strings or comments but
" in a less general fashion.
let s:skip_regex2 = '\<ruby\%(String' .
      \ '\|Interpolation\|NoInterpolation\|Escape\|Comment\|Documentation\)\>'

" Items in this regex are syntax groups that delimit strings.
let s:skip_regex3 = '\<ruby\%(String' .
      \ '\|Interpolation\|NoInterpolation\|Escape\)\>'

" This regex is used for matching words that, at the start of a line, add
" a level of indent.
let s:ruby_indent_keywords = '^\s*\%(\zs\<\%(module\|class\|def\|if\|for' .
      \ '\|while\|until\|else\|elsif\|case\|when\|unless\|begin\|ensure' .
      \ '\|rescue\)\>\|\h\w*\s*=\s*\zs\<\%(if\|unless\|while\|until\)\)'

" Regular expression for continuations.
let s:continuation_regexp = '\%([\\*+/.,=-]\|\W?\|||\|&&\)\s*\%(#.*\)\=$'
let s:continuation_regexp2 = '\%([\\*+/.,=({[-]\|\W?\|||\|&&\)\s*\%(#.*\)\=$'

" Regular expression for blocks.  We can't check for {, it's done in another
" place.
let s:block_regexp = '\%(\<do\>\|{\)\s*\%(|\%([*@]\=\h\w*,\=\s*\)\+|\)\=\s*' .
      \ '\%(#.*\)\=$'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = 'synIDattr(synID(line("."), col("."), 0), "name") =~ ' .
      \ "'".s:skip_regex."'"

" Expression used for searchpair() call for finding match for 'end'.
let s:end_skip_expr = s:skip_expr .
      \ ' || (expand("<cword>") =~ "\\<\\(if\\|unless\\|while\\|until\\)\\>"' .
      \ ' && getline(".") !~ "^\\s*\\<".expand("<cword>")."\\>"' .
      \ ' && getline(".") !~ "\\h\\w*\\s*=\\s*\\<".expand("<cword>")."\\>"' .
      \ ' && getline(".") !~ expand("<cword>")."\\>.*\\<end\\>")'

" 2. Auxiliary Functions {{{1
" ======================

" Move the cursor to the given line:col.
function s:GotoLineCol(line, col)
  if a:col != 0
    execute 'normal! '.a:line.'G0'.a:col.'l'
  else
    execute 'normal! '.a:line.'G0'
  endif
endfunction

" Check if the character at lnum:col is inside a string, comment, or is ascii.
function s:IsInStringOrComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~ s:skip_regex
endfunction

" Check if the character at lnum:col is inside a string or comment.
function s:IsInStringOrComment2(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~ s:skip_regex2
endfunction

" Check if the character at lnum:col is inside a string.
function s:IsInString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~ s:skip_regex3
endfunction

" Find the previous non-blank line which isn't a comment-line or in a comment
" block.
function s:PrevNonBlankNonString(lnum)
  let in_block = 0
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    let line = getline(lnum)
    " Go in and out of blocks depending on if the line matches this.
    " Also skip the line if it contains only whitespace and a comment.
    " Lastly, skip it if it is in a multi-line string.
    if !in_block && line =~ '^=end$'
      let in_block = 1
    elseif in_block && line =~ '^=begin$'
      let in_block = 0
    elseif !in_block && line !~ '^\s*#.*$'
	  \ && !(s:IsInStringOrComment(lnum, 1)
	  \ && s:IsInStringOrComment(lnum, strlen(getline(lnum))))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Get the Most Significant Line before lnum.  This is the line that started
" the continuation lnum may be a part of.
function s:GetMSL(lnum)
  " Start on the line we're at and use its indent.
  let msl = a:lnum
  let lnum = s:PrevNonBlankNonString(a:lnum - 1)
  while lnum > 0
    " If we have a continuation line which isn't in a string, use that
    " lines instead of the one we previously had.
    " Otherwise, we are done.
    let line = getline(lnum)
    let col = match(line, s:continuation_regexp2) + 1
    if (col > 0 && !s:IsInStringOrComment(lnum, col))
	  \ || s:IsInString(lnum, strlen(line))
      let msl = lnum
    else
      break
    endif
    let lnum = s:PrevNonBlankNonString(lnum - 1)
  endwhile
  return msl
endfunction

" Check if line has more opening parentheses than closing
function s:LineHasOpeningParen(lnum)
  let lnum = a:lnum
  let line = getline(lnum)
  let i = 0
  let n = strlen(line)
  let open_0 = 0
  let open_2 = 0
  let open_4 = 0
  while i < n
    let idx = stridx('(){}[]', line[i])
    if idx > -1 && !s:IsInStringOrComment(lnum, i + 1)
      if idx % 2 == 0
	let open_{idx} = open_{idx} + 1
      else
	let open_{idx - 1} = open_{idx - 1} - 1
      endif
    endif
    let i = i + 1
  endwhile
  return (open_0 > 0) . (open_2 > 0) . (open_4 > 0)
endfunction

" 3. GetRubyIndent Function {{{1
" =========================

function GetRubyIndent()
  " 3.1. Setup {{{2
  " ----------

  " Set up variables for restoring position in file.  Could use v:lnum here.
  let vcol = col('.')

  " 3.2. Work on the current line {{{2
  " -----------------------------

  " Get the current line.
  let line = getline(v:lnum)
  let ind = -1

  " If we got a closing bracket on an empty line, find its match and indent
  " according to it.
  let col = match(line, '^\s*\zs[]})]') + 1
  if col > 0 && !s:IsInStringOrComment(v:lnum, col)
    call s:GotoLineCol(v:lnum, col - 1)
    " If it was a parentheses, search for its match and indent to its level.
    " If it was a brace or bracket, search for its match and indent to that
    " lines level.
    if line[col - 1] == ')' && searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = virtcol('.') - 1
    else
      let begin = '{'
      let end = '}'
      if line[col - 1] == ']'
	let begin = '['
	let end = ']'
      endif
      " If we find a matching brace/bracket, we need to find the line it
      " belongs to and indent to that line's level of indent.
      if searchpair(begin, '', end, 'bW', s:skip_expr) > 0
	let ind = indent(s:GetMSL(line('.')))
      endif
    endif
    return ind
  endif

  " If we have a =begin or =end set indent to first column.
  let col = match(line, '^\s*\zs\%(=begin\|=end\)$') + 1
  if col > 0
    return 0
  endif

  " If we have a deindenting keyword on an empty line, find its match and
  " indent to its level.
  let col = match(line,
	\ '^\s*\zs\<\%(ensure\|else\|rescue\|elsif\|when\|end\)\>') + 1
  if col > 0 && !s:IsInStringOrComment(v:lnum, col)
    call s:GotoLineCol(v:lnum, 0)
    if searchpair('\<\%(def\|do\|if\|unless\|case\|begin\|until\|for\|while' .
	  \ '\|\.\@<!class\|\.\@<!module\)\>',
	  \ '\<\%(ensure\|else\|rescue\|when\|elsif\)\>', '\<end\>', 'bW',
	  \ s:end_skip_expr) > 0
      let ind = indent('.')
    endif
    return ind
  endif

  " If we are in a multi-line string or line-comment, don't do anything to it.
  if s:IsInStringOrComment2(v:lnum, matchend(line, '^\s*') + 1)
    return indent('.')
  endif

  " 3.3. Work on the previous line. {{{2
  " -------------------------------

  " Find a non-blank, non-multi-line string line above the current line.
  let lnum = s:PrevNonBlankNonString(v:lnum - 1)

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  " Set up variables for current line.
  let line = getline(lnum)
  let ind = indent(lnum)

  " If the previous line ended with a block opening, add a level of indent.
  let col = match(line, s:block_regexp) + 1
  if col > 0 && !s:IsInStringOrComment(lnum, col)
    return indent(s:GetMSL(lnum)) + &sw
  endif

  " If the previous line contained an opening bracket, and we are still in it,
  " add one level of indent.
  if line =~ '[[({]'
    let counts = s:LineHasOpeningParen(lnum)
    if counts[0] == '1'
	  \&& searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      return virtcol('.')
    elseif (counts[1] == '1' || counts[2] == '1')
      return ind + &sw
    else
      call s:GotoLineCol(v:lnum, vcol - 1)
    end
  endif

  " 3.4. Work on the MSL line. {{{2
  " --------------------------

  let p_lnum = lnum
  let lnum = s:GetMSL(lnum)

  " Continuation line
  let ccol = match(line, s:continuation_regexp) + 1
  if lnum != p_lnum && ccol > 0 && !s:IsInStringOrComment(p_lnum, ccol)
	\ || s:IsInString(p_lnum, strlen(line))
    return ind
  endif

  let line = getline(lnum)
  let msl_ind = indent(lnum)
"  if indent(lnum) < ind
"    let ind = indent(lnum)
"  endif

  " If the previous line began with an indenting keyword, add a level of
  " indent.
  " TODO: this does not take into account contrived things such as
  " module Foo; class Bar; end
  let col = match(line, s:ruby_indent_keywords) + 1
  if col > 0 && !s:IsInStringOrComment(lnum, col)
    let ind = msl_ind + &sw
    let col = match(line, '\<end\>\s*\%(#.*\)\=$') + 1
    if col > 0 && !s:IsInStringOrComment(lnum, col)
      let ind = ind - &sw
    endif
    return ind
  endif

  " If the previous line ended with [*+/.-=], indent one extra level.
  let ccol = match(line, s:continuation_regexp) + 1
  if ccol > 0 && !s:IsInStringOrComment(lnum, ccol)
    if lnum == p_lnum
      let ind = msl_ind + &sw
    else
      let ind = msl_ind
    endif
  endif

  " }}}2

  return ind
endfunction

" }}}1

" vim: sw=2 sts=2 ts=8 ff=unix:
