" Vim indent file
" Language:	Ruby
" Maintainer:	Gavin Sinclair <gsinclair at soyabean.com.au>
" Developer:	Nikolai Weibull <lone-star at home.se>
" Info:		$Id: ruby.vim,v 1.15 2003/10/10 22:45:12 pcp Exp $
" URL:		http://vim-ruby.sourceforge.net
" Anon CVS:	See above site
" Licence:	GPL (http://www.gnu.org)
" Disclaimer:
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue
setlocal indentkeys+=0),0],==begin,==end

" Only define the function once.
if exists("*GetRubyIndent")
  finish
endif

let s:skip_regex = '\<ruby\%(String\|StringDelimiter\|ASCIICode'.
      \'\|Interpolation\|NoInterpolation\|Escape\|Comment\|Documentation\)\>'
let s:skip_regex2 = '\<ruby\%(String\|Interpolation\|NoInterpolation\|Escape'.
      \'\|Comment\|Documentation\)\>'
" Check if the character at lnum:col is inside a string or comment.
function s:IsInStringOrComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~ s:skip_regex
endfunction

" Check if the character at lnum:col is inside a string or comment.
" Works like s:IsInStringOrComment(), with the difference that string-delimits
" are not matched.
function s:IsInStringOrComment2(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 0), 'name') =~ s:skip_regex2
endfunction

" These comma-separated list of words at the beginning of a line add a level
" of indent.
let g:ruby_indent_keywords = 'module,class,def,if,for,while,until,else,' .
      \'elsif,case,when,unless,begin,ensure,rescue'

" Build a regular expression from the g:ruby_indent_keywords variable.
" The result is stored in s:ruby_indent_keywords.
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

" Regular expression for continuations.
let s:continuation_regexp = '[\\*+/.,=({[-]\s*\(#.*\)\=$'

" Regular expression for blocks.  We can't check for {, it's done in another
" place.
let s:block_regexp = '\<do\>\s*\(|\([*@]\=\h\w*\(,\s*\)\=\)\+|\s*\)\=\(#.*\)\=$'

" Expression used to check whether we should skip a match with searchpair().
" XXX: this should be expanded some how with class and module to avoid
" confusion with object.class.foo stuff.
let s:skip_expr = "synIDattr(synID(line('.'), col('.'), 0), 'name') =~ '".s:skip_regex."'"
let s:end_skip_expr = s:skip_expr.' || (expand("<cword>") =~ "\\<if\\>\\|\\<unless\\>\\|\\<while\\>\\|\\<until\\>" && getline(".") !~ "^\\s*\\<".expand("<cword>")."\\>" && getline(".") !~ expand("<cword>")."\\>.*\\<end\\>")'

" Find the previous non-blank line which isn't a comment-line or in a comment
" block.
function s:PrevNonBlank(lnum)
  let in_block = 0
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    let line = getline(lnum)
    " If the line is the end of an embedded document, beginning skipping.
    if !in_block && line =~ '^=end$'
      let in_block = 1
    " Else, if the line is the beginning of an embedded document, end
    " skipping.
    elseif in_block && line =~ '^=begin$'
      let in_block = 0
    " Otherwise, if we aren't in an embedded document, check if the line is a
    " comment line, and, if so, skip it.
    elseif !in_block && line !~ '^\s*#.*$'
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Move the cursor to the given line:col.
function s:GotoLineCol(line, col)
  if a:col != 0
    execute 'normal! '.a:line.'G0'.a:col.'l'
  else
    execute 'normal! '.a:line.'G0'
  endif
endfunction

" Check if line has more opening parentheses than closing
function s:LineHasOpeningParen(line, lnum)
  let i = 0
  let n = strlen(a:line)
  let open_paren = 0
  let open_brace = 0
  let open_bracket = 0
  while i < n
    let c = a:line[i]
    if c =~ '[](){}[]'
	  \&& synIDattr(synID(a:lnum, i + 1, 0), 'name') !~ s:skip_regex
      if c == '(' || c == ')'
	let open_paren = open_paren + (c == '(' ? 1 : -1)
      elseif c == '{' || c == '}'
	let open_brace = open_brace + (c == '{' ? 1 : -1)
      elseif c == '[' || c == '['
	let open_bracket = open_bracket + (c == '[' ? 1 : -1)
      endif
    endif
    let i = i + 1
  endwhile
  return "" . (open_paren ? 1 : 0).(open_brace ? 1 : 0).(open_bracket ? 1 : 0)
endfunction

function GetRubyIndent()
  " Part 1: Setup.
  " ==============

  " Set up variables for restoring position in file.  Could use v:lnum here.
  let vcol = col('.')

  " Part 2: Work on the current line.
  " =================================

  " Get the current line.
  let line = getline(v:lnum)
  let ind = -1

  " If we got a closing bracket on an empty line, deindent one level or match
  " the column in case of a parentheses.
  let col = match(line, '^\s*\zs[]})]') + 1
  if col > 0 && !s:IsInStringOrComment(v:lnum, col)
    call s:GotoLineCol(v:lnum, col - 1)
    " If it was a parentheses, search for its match and indent to its level.
    if line[col - 1] == ')' && searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = virtcol('.') - 1
    " Else, if it was a brace, search for its match and find the line to which
    " it belongs and indent to that lines level.
    elseif line[col - 1] == '}'
	  \ && searchpair('{', '', '}', 'bW', s:skip_expr) > 0
      let p_lnum = line('.')
      let my_lnum = s:PrevNonBlank(p_lnum - 1)
      while my_lnum > 0
	let my_line = getline(my_lnum)
	let col = match(my_line, s:continuation_regexp) + 1
	" If the line was a continuation not in a string, and we are currently
	" not in a multiline-string, get it's indent and continue to previous
	" line.
	if col > 0 && !s:IsInStringOrComment(my_lnum, col)
	  let p_lnum = my_lnum
	  let my_lnum = s:PrevNonBlank(my_lnum - 1)
	" Else, if we are in a multi-line string, continue to previous line.
	" TODO: are these offsets correct?
	elseif s:IsInStringOrComment(my_lnum, 1)
	  let my_lnum = s:PrevNonBlank(my_lnum - 1)
	" Otherwise, exit the loop
	else
	  let my_lnum = -1
	endif
      endwhile
      let ind = indent(p_lnum)
    " Otherwise, it was a bracket, so search for it and indent to the matching
    " lines level.
    elseif searchpair('\[', '', '\]', 'bW', s:skip_expr) > 0
      let ind = indent('.')
    end
    call s:GotoLineCol(v:lnum, vcol - 1)
  endif

  " If we get a =begin, =end, or here-doc ender set deindent to first column.
  " XXX: skip here-docs at the moment: \|EO[FSL]\|EOHELP
  let col = match(line, '^\s*\zs\(=begin\|=end\)') + 1
  if col > 0
    let ind = 0
  endif

  " If we got a deindenting line on an empty line, find match and indent to
  " its level.
  let col = match(line,
	\'^\s*\zs\(ensure\>\|else\>\|rescue\>\|elsif\>\|when\>\|end\>\)') + 1
  if col > 0 && !s:IsInStringOrComment(v:lnum, col)
    call s:GotoLineCol(v:lnum, 0)
    " Find the matching parent statement to it
    " XXX: fixed the .class problem here, but I don't know if its the best way
    " to do it
    if searchpair('\<def\>\|\<do\>\|\<if\>\|\<unless\>\|\<case\>\|' . 
	  \'\<begin\>\|\<until\>\|\<for\>\|\<while\>\|' .
	  \'\<\.\@<!class\>\|\<\.\@<!module\>', 
	  \'\<ensure\>\|\<else\>\|\<rescue\>\|\<elsif\>\|\<when\>', '\<end\>',
	  \'bW', s:end_skip_expr) > 0
      let ind = indent('.')
    endif
    call s:GotoLineCol(v:lnum, vcol - 1)
  endif

  " If we got some indentation, use it
  if ind != -1
    return ind
  " Otherwise, check if we are in a multi-line string or line-comment and, if
  " so, skip it.
  " TODO: this needs more checking though
  elseif s:IsInStringOrComment2(v:lnum, matchend(line, '^\s*') + 1)
    return indent('.')
  endif

  " Part 3: Work on the previous line.
  " ==================================

  " Find a non-blank line above the current line.
  let lnum = s:PrevNonBlank(v:lnum - 1)

  " Ignore multi-line strings
  " TODO: check this positioning
  " TODO: is it necessary to check both ends?
  while lnum > 0
    if s:IsInStringOrComment(lnum, 1) &&
	  \ s:IsInStringOrComment(lnum, strlen(getline(lnum)))
      let lnum = s:PrevNonBlank(lnum - 1)
    else
      break
    endif
  endwhile

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  " Set up variables for current line.
  let line = getline(lnum)
  let ind = indent(lnum)
  let did_kw_indent = 0
  let did_con_indent = 0

  " If the previous line began with an indenting keyword, add one level.
  let kcol = match(line, '^\s*'.s:ruby_indent_keywords) + 1
  let bcol = match(line, s:block_regexp) + 1
  if (kcol > 0 && !s:IsInStringOrComment(lnum, kcol))
	\ || (bcol > 0 && !s:IsInStringOrComment(lnum, bcol))
    let ind = ind + &sw
    let did_kw_indent = 1
  endif

  " If the previous line ended in a brackets, get the indent of the line
  " that opened it.
  " TODO: add comments to this part
  if !did_kw_indent
    let bcol = match(line,
	  \'[]})]\s*\(\(\<if\>\|\<unless\>\|\<until\>\|\<while\>\|#\).*\)\=$') + 1
    if bcol > 0 && !s:IsInStringOrComment(lnum, bcol)
      call s:GotoLineCol(lnum, bcol - 1)
      let open = '('
      let close = ')'
      if line[bcol - 1] == '}'
	let open = '{'
	let close = '}'
      elseif line[bcol - 1] == ']'
	let open = '\['
	let close = '\]'
      endif
      if searchpair(open, '', close, 'bW', s:skip_expr) > 0
	let kcol = match(getline('.'), '^\s*'.s:ruby_indent_keywords) + 1
	if (kcol > 0 && !s:IsInStringOrComment(line('.'), kcol))
	  let ind = indent('.') + &sw
	  let did_kw_indent = 1
	else
	  let ind = indent('.')
	  let did_con_indent = 1
	endif
      endif
      call s:GotoLineCol(v:lnum, vcol - 1)
    endif
  endif

  " If the previous line was a continuation line, indent to match its parent.
  " TODO: this gets executed a bit too often perhaps (with the string
  " checking)
  let p_line = line
  let p_lnum = lnum
  if !did_kw_indent && !did_con_indent
    let my_lnum = s:PrevNonBlank(lnum - 1)
    while my_lnum > 0
      let my_line = getline(my_lnum)
      let col = match(my_line, s:continuation_regexp) + 1
      " If the line was a continuation not in a string, and we are currently
      " not in a multiline-string, get it's indent and continue to previous
      " line.
      if (col > 0 && !s:IsInStringOrComment(my_lnum, col))
"	    \ && !s:IsInStringOrComment(p_lnum, strlen(p_line))
	let ind = indent(my_lnum)
	let p_line = my_line
	let p_lnum = my_lnum
	let my_lnum = s:PrevNonBlank(my_lnum - 1)
      " Else, if we are in a multi-line string, continue to previous line.
      elseif s:IsInStringOrComment(my_lnum, strlen(my_line))
	let my_lnum = s:PrevNonBlank(my_lnum - 1)
      " Otherwise, exit the loop
      else
	let my_lnum = -1
      endif
    endwhile
  endif

  " If the previous line ended with [*+/.-=], indent one extra level.
  if !did_kw_indent && !did_con_indent
    let ccol = match(line, s:continuation_regexp) + 1
    if ccol > 0 && !s:IsInStringOrComment(lnum, ccol)
      let ind = ind + &sw
" XXX:
      let did_con_indent = 1
    endif
  endif

  " If we indented and the line ended with an 'end', decrease indent.
  if did_kw_indent
    let col = match(line, '\<end\>\s*\(#.*\)\=$') + 1
    if col > 0 && !s:IsInStringOrComment(lnum, col)
      let ind = ind - &sw
    endif
  endif

  " TODO: look over merging the two below somehow (and see what's needed)

  " If the previous line contained an opening bracket, and we are still in it,
  " add one level of indent.
  let did_virt_indent = 0
  if line =~ '[[({]'
    let counts = s:LineHasOpeningParen(line, lnum)
    if counts[0] == '1'
	  \&& searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = virtcol('.')
      let did_virt_indent = 1
    elseif !did_con_indent && (counts[1] == '1' || counts[2] == '1')
      let ind = ind + &sw
      let did_virt_indent = 1
    end
    call s:GotoLineCol(v:lnum, vcol - 1)
  endif

  " If the far previous line contained an opening bracket, and we are still in
  " it, add one level of indent.
  " TODO: do we really need to check for did_con_indent here?  don't think so
  if !did_virt_indent && p_line =~ '[[({]'
    let counts = s:LineHasOpeningParen(p_line, p_lnum)
    if counts[0] == '1'
	  \&& searchpair('(', '', ')', 'bW', s:skip_expr) > 0
      let ind = virtcol('.')
    elseif !did_con_indent && (counts[1] == '1' || counts[2] == '1')
      let ind = ind + &sw
    end
    call s:GotoLineCol(v:lnum, vcol - 1)
  endif

  return ind
endfunction

" vim: sw=2 sts=2 ts=8 ff=unix:
