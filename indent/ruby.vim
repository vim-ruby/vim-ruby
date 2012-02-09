" Vim indent file
" Language:		Ruby
" Maintainer:		Nikolai Weibull <now at bitwi.se>
" URL:			https://github.com/vim-ruby/vim-ruby
" Anon CVS:		See above site
" Release Coordinator:	Doug Kearns <dougkearns@gmail.com>

" 0. Initialization {{{1
" =================

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal nosmartindent

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetRubyIndent(v:lnum)
setlocal indentkeys=0{,0},0),0],!^F,o,O,e
setlocal indentkeys+==end,=else,=elsif,=when,=ensure,=rescue,==begin,==end

" Only define the function once.
if exists("*GetRubyIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" 1. Variables {{{1
" ============

" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = '\<ruby\%(Regexp\|RegexpDelimiter' .
      \ '\|String\|StringEscape\|ASCIICode' .
      \ '\|Interpolation\|NoInterpolation\|Comment\|Documentation\)\>'

" Regex of syntax group names that are strings.
let s:syng_string =
      \ '\<ruby\%(String\|Interpolation\|NoInterpolation\|StringEscape\)\>'

" Regex of syntax group names that are strings or documentation.
let s:syng_stringdoc =
      \'\<ruby\%(String\|Interpolation\|NoInterpolation\|StringEscape\|Documentation\)\>'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr =
      \ "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".s:syng_strcom."'"

" Regex used for words that, at the start of a line, add a level of indent.
let s:ruby_indent_keywords = '^\s*\zs\<\%(module\|class\|def\|if\|for' .
      \ '\|while\|until\|else\|elsif\|case\|when\|unless\|begin\|ensure' .
      \ '\|rescue\):\@!\>' .
      \ '\|\%([=,*/%+-]\|<<\|>>\|:\s\)\s*\zs' .
      \    '\<\%(if\|for\|while\|until\|case\|unless\|begin\):\@!\>'

" Regex used for words that, at the start of a line, remove a level of indent.
let s:ruby_deindent_keywords =
      \ '^\s*\zs\<\%(ensure\|else\|rescue\|elsif\|when\|end\):\@!\>'

" Regex that defines the start-match for the 'end' keyword.
"let s:end_start_regex = '\%(^\|[^.]\)\<\%(module\|class\|def\|if\|for\|while\|until\|case\|unless\|begin\|do\)\>'
" TODO: the do here should be restricted somewhat (only at end of line)?
let s:end_start_regex = '^\s*\zs\<\%(module\|class\|def\|if\|for' .
      \ '\|while\|until\|case\|unless\|begin\):\@!\>' .
      \ '\|\%([=,*/%+-]\|<<\|>>\|:\s\)\s*\zs' .
      \    '\<\%(if\|for\|while\|until\|case\|unless\|begin\):\@!\>' .
      \ '\|\<do:\@!\>'

" Regex that defines the middle-match for the 'end' keyword.
let s:end_middle_regex = '\<\%(ensure\|else\|\%(\%(^\|;\)\s*\)\@<=\<rescue:\@!\>\|when\|elsif\):\@!\>'

" Regex that defines the end-match for the 'end' keyword.
let s:end_end_regex = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'

" Expression used for searchpair() call for finding match for 'end' keyword.
let s:end_skip_expr = s:skip_expr .
      \ ' || (expand("<cword>") == "do"' .
      \ ' && getline(".") =~ "^\\s*\\<\\(while\\|until\\|for\\):\\@!\\>")'

" Regex that defines continuation lines, not including (, {, or [.
let s:non_bracket_continuation_regex = '\%([\\.,:*/%+]\|\<and\|\<or\|\%(<%\)\@<![=-]\|\W[|&?]\|||\|&&\)\s*\%(#.*\)\=$'

" Regex that defines continuation lines.
" TODO: this needs to deal with if ...: and so on
let s:continuation_regex =
      \ '\%([({[\\.,:*/%+]\|\<and\|\<or\|\%(<%\)\@<![=-]\|\W[|&?]\|||\|&&\)\s*\%(#.*\)\=$'

" Regex that defines bracket continuations
let s:bracket_continuation_regex = '\%([({[]\)\s*\%(#.*\)\=$'

" Regex that defines blocks.
let s:block_regex =
      \ '\%(\<do:\@!\>\|{\)\s*\%(|\%([*@]\=\h\w*,\=\s*\)\%(,\s*[*@]\=\h\w*\)*|\)\=\s*\%(#.*\)\=$'

" 2. Auxiliary Functions {{{1
" ======================

" Check if the character at lnum:col is inside a string, comment, or is ascii.
function s:IsInStringOrComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_strcom
endfunction

" Check if the character at lnum:col is inside a string.
function s:IsInString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_string
endfunction

" Check if the character at lnum:col is inside a string or documentation.
function s:IsInStringOrDocumentation(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_stringdoc
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevNonBlankNonString(lnum)
  let in_block = 0
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    " Go in and out of blocks comments as necessary.
    " If the line isn't empty (with opt. comment) or in a string, end search.
    let line = getline(lnum)
    if line =~ '^=begin'
      if in_block
        let in_block = 0
      else
        break
      endif
    elseif !in_block && line =~ '^=end'
      let in_block = 1
    elseif !in_block && line !~ '^\s*#.*$' && !(s:IsInStringOrComment(lnum, 1)
          \ && s:IsInStringOrComment(lnum, strlen(line)))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Find line above 'lnum' that started the continuation 'lnum' may be part of.
function s:GetMSL(lnum)
  " Start on the line we're at and use its indent.
  let msl = a:lnum
  let msl_body = getline(msl)
  let lnum = s:PrevNonBlankNonString(a:lnum - 1)
  while lnum > 0
    " If we have a continuation line, or we're in a string, use line as MSL.
    " Otherwise, terminate search as we have found our MSL already.
    let line = getline(lnum)

    if line =~ s:non_bracket_continuation_regex && msl_body =~ s:non_bracket_continuation_regex
      " If the current line is a non-bracket continuation and so is the
      " previous one, keep its indent and continue looking for an MSL.
      let msl = lnum
    elseif line =~ s:non_bracket_continuation_regex && (msl_body =~ s:bracket_continuation_regex || msl_body =~ s:block_regex)
      " If the current line is a bracket continuation or a block-starter, but
      " the previous is a non-bracket one, respect the previous' indentation,
      " and stop here.
      return lnum
    elseif line =~ s:bracket_continuation_regex && (msl_body =~ s:bracket_continuation_regex || msl_body =~ s:block_regex)
      " If both lines are bracket continuations (the current may also be a
      " block-starter), use the current one's and stop here
      return msl
    else
      let col = match(line, s:continuation_regex) + 1
      if (col > 0 && !s:IsInStringOrComment(lnum, col))
            \ || s:IsInString(lnum, strlen(line))
        let msl = lnum
      else
        break
      endif
    endif

    let msl_body = getline(msl)
    let lnum = s:PrevNonBlankNonString(lnum - 1)
  endwhile
  return msl
endfunction

" Check if line 'lnum' has more opening brackets than closing ones.
function s:FindRightmostOpenBracket(lnum)
  let open = {'parentheses': [], 'braces': [], 'brackets': []}
  let line = getline(a:lnum)
  let pos = match(line, '[][(){}]', 0)
  while pos != -1
    if !s:IsInStringOrComment(a:lnum, pos + 1)
      if line[pos] == '('
        call add(open.parentheses, {'type': '(', 'pos': pos})
      elseif line[pos] == ')'
        let open.parentheses = open.parentheses[0:-2]
      elseif line[pos] == '{'
        call add(open.braces, {'type': '{', 'pos': pos})
      elseif line[pos] == '}'
        let open.braces = open.braces[0:-2]
      elseif line[pos] == '['
        call add(open.brackets, {'type': '[', 'pos': pos})
      elseif line[pos] == ']'
        let open.brackets = open.brackets[0:-2]
      endif
    endif
    let pos = match(line, '[][(){}]', pos + 1)
  endwhile
  let rightmost = {'type': '(', 'pos': -1}
  for open in open.parentheses + open.braces + open.brackets
    if open.pos > rightmost.pos
      let rightmost = open
    endif
  endfor
  return rightmost
endfunction

function s:Match(lnum, regex)
  let col = match(getline(a:lnum), '\C'.a:regex) + 1
  return col > 0 && !s:IsInStringOrComment(a:lnum, col) ? col : 0
endfunction

function s:MatchLast(lnum, regex)
  let line = getline(a:lnum)
  let col = match(line, '.*\zs' . a:regex)
  while col != -1 && s:IsInStringOrComment(a:lnum, col)
    let line = strpart(line, 0, col)
    let col = match(line, '.*' . a:regex)
  endwhile
  return col + 1
endfunction

" 3. GetRubyIndent Function {{{1
" =========================

function GetRubyIndent(...)
  " 3.1. Setup {{{2
  " ----------

  " For the current line, use the first argument if given, else v:lnum
  let clnum = a:0 ? a:1 : v:lnum

  " Set up variables for restoring position in file.  Could use clnum here.
  let vcol = col('.')

  " 3.2. Work on the current line {{{2
  " -----------------------------

  " Get the current line.
  let line = getline(clnum)
  let ind = -1

  " If we got a closing bracket on an empty line, find its match and indent
  " according to it.  For parentheses we indent to its column - 1, for the
  " others we indent to the containing line's MSL's level.  Return -1 if fail.
  let col = matchend(line, '^\s*[]})]')
  if col > 0 && !s:IsInStringOrComment(clnum, col)
    call cursor(clnum, col)
    let bs = strpart('(){}[]', stridx(')}]', line[col - 1]) * 2, 2)
    if searchpair(escape(bs[0], '\['), '', bs[1], 'bW', s:skip_expr) > 0
      if line[col-1]==')' && col('.') != col('$') - 1
        let ind = virtcol('.') - 1
      else
        let ind = indent(s:GetMSL(line('.')))
      endif
    endif
    return ind
  endif

  " If we have a =begin or =end set indent to first column.
  if match(line, '^\s*\%(=begin\|=end\)$') != -1
    return 0
  endif

  " If we have a deindenting keyword, find its match and indent to its level.
  " TODO: this is messy
  if s:Match(clnum, s:ruby_deindent_keywords)
    call cursor(clnum, 1)
    if searchpair(s:end_start_regex, s:end_middle_regex, s:end_end_regex, 'bW',
          \ s:end_skip_expr) > 0
      let line = getline('.')
      if strpart(line, 0, col('.') - 1) =~ '=\s*$' &&
            \ strpart(line, col('.') - 1, 2) !~ 'do'
        let ind = virtcol('.') - 1
      else
        let ind = indent(s:GetMSL(line('.')))
      endif
    endif
    return ind
  endif

  " If we are in a multi-line string or line-comment, don't do anything to it.
  if s:IsInStringOrDocumentation(clnum, matchend(line, '^\s*') + 1)
    return indent('.')
  endif

  " 3.3. Work on the previous line. {{{2
  " -------------------------------

  " Find a non-blank, non-multi-line string line above the current line.
  let lnum = s:PrevNonBlankNonString(clnum - 1)

  " If the line is empty and inside a string, use the previous line.
  if line =~ '^\s*$' && lnum != prevnonblank(clnum - 1)
    return indent(prevnonblank(clnum))
  endif

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  " Set up variables for current line.
  let line = getline(lnum)
  let ind = indent(lnum)

  " If the previous line ended with a block opening, add a level of indent.
  if s:Match(lnum, s:block_regex)
    return indent(s:GetMSL(lnum)) + &sw
  endif

  " If the previous line contained an opening bracket, and we are still in it,
  " add indent depending on the bracket type.
  if line =~ '[[({]'
    let open = s:FindRightmostOpenBracket(lnum)
    if open.pos != -1
      if open.type == '(' && searchpair('(', '', ')', 'bW', s:skip_expr) > 0
        if col('.') + 1 == col('$')
          return ind + &sw
        else
          return virtcol('.')
        endif
      else
        let nonspace = matchend(line, '\S', open.pos + 1) - 1
        return nonspace > 0 ? nonspace : ind + &sw
      endif
    else
      call cursor(clnum, vcol)
    end
  endif

  " If the previous line ended with an "end", match that "end"s beginning's
  " indent.
  let col = s:Match(lnum, '\%(^\|[^.:@$]\)\<end\>\s*\%(#.*\)\=$')
  if col > 0
    call cursor(lnum, col)
    if searchpair(s:end_start_regex, '', s:end_end_regex, 'bW',
          \ s:end_skip_expr) > 0
      let n = line('.')
      let ind = indent('.')
      let msl = s:GetMSL(n)
      if msl != n
        let ind = indent(msl)
      end
      return ind
    endif
  end

  let col = s:Match(lnum, s:ruby_indent_keywords)
  if col > 0
    call cursor(lnum, col)
    let ind = virtcol('.') - 1 + &sw
    " TODO: make this better (we need to count them) (or, if a searchpair
    " fails, we know that something is lacking an end and thus we indent a
    " level
    if s:Match(lnum, s:end_end_regex)
      let ind = indent('.')
    endif
    return ind
  endif

  " 3.4. Work on the MSL line. {{{2
  " --------------------------

  " Set up variables to use and search for MSL to the previous line.
  let p_lnum = lnum
  let lnum = s:GetMSL(lnum)

  " If the previous line wasn't a MSL and is continuation return its indent.
  " TODO: the || s:IsInString() thing worries me a bit.
  if p_lnum != lnum
    if s:Match(p_lnum,s:non_bracket_continuation_regex)||s:IsInString(p_lnum,strlen(line))
      return ind
    endif
  endif

  " Set up more variables, now that we know we wasn't continuation bound.
  let line = getline(lnum)
  let msl_ind = indent(lnum)

  " If the MSL line had an indenting keyword in it, add a level of indent.
  " TODO: this does not take into account contrived things such as
  " module Foo; class Bar; end
  if s:Match(lnum, s:ruby_indent_keywords)
    let ind = msl_ind + &sw
    if s:Match(lnum, s:end_end_regex)
      let ind = ind - &sw
    endif
    return ind
  endif

  " If the previous line ended with [*+/.,-=], but wasn't a block ending,
  " indent one extra level.
  if s:Match(lnum, s:non_bracket_continuation_regex) && !s:Match(lnum, '^\s*\(}\|end\)')
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

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:set sw=2 sts=2 ts=8 et:
