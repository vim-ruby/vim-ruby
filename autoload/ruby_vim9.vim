vim9script

# 1. Variables {{{1
# ============

# Syntax group names that are strings.
var syng_string =
      \ ['String', 'Interpolation', 'InterpolationDelimiter', 'StringEscape']

# Syntax group names that are strings or documentation.
var syng_stringdoc = syng_string + ['Documentation']

# Syntax group names that are or delimit strings/symbols/regexes or are comments.
var syng_strcom = syng_stringdoc + [
      \ 'Character',
      \ 'Comment',
      \ 'HeredocDelimiter',
      \ 'PercentRegexpDelimiter',
      \ 'PercentStringDelimiter',
      \ 'PercentSymbolDelimiter',
      \ 'Regexp',
      \ 'RegexpCharClass',
      \ 'RegexpDelimiter',
      \ 'RegexpEscape',
      \ 'StringDelimiter',
      \ 'Symbol',
      \ 'SymbolDelimiter',
      \ ]

# Expression used to check whether we should skip a match with searchpair().
var skip_expr =
      \ 'index(mapnew(' .. string(syng_strcom) .. ', "hlID(''ruby'' .. v:val)"), synID(line("."), col("."), 1)) >= 0'

# Regex used for words that, at the start of a line, add a level of indent.
var ruby_indent_keywords =
      \ '^\s*\zs\<\%(module\|class\|if\|for' ..
      \   '\|while\|until\|else\|elsif\|case\|when\|in\|unless\|begin\|ensure\|rescue' ..
      \   '\|\%(\K\k*[!?]\?\s\+\)\=def\):\@!\>' ..
      \ '\|\%([=,*/%+-]\|<<\|>>\|:\s\)\s*\zs' ..
      \    '\<\%(if\|for\|while\|until\|case\|unless\|begin\):\@!\>'

# Def without an end clause: def method_call(...) = <expression>
var ruby_endless_def = '\<def\s\+\k\+[!?]\=\%((.*)\|\s\)\s*='

# Regex used for words that, at the start of a line, remove a level of indent.
var ruby_deindent_keywords =
      \ '^\s*\zs\<\%(ensure\|else\|rescue\|elsif\|when\|in\|end\):\@!\>'

# Regex that defines the start-match for the 'end' keyword.
# let end_start_regex = '\%(^\|[^.]\)\<\%(module\|class\|def\|if\|for\|while\|until\|case\|unless\|begin\|do\)\>'
# TODO: the do here should be restricted somewhat (only at end of line)?
var end_start_regex =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' ..
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' ..
      \   '\|\%(\K\k*[!?]\?\s\+\)\=def\):\@!\>' ..
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

# Regex that defines the middle-match for the 'end' keyword.
var end_middle_regex = '\<\%(ensure\|else\|\%(\%(^\|;\)\s*\)\@<=\<rescue:\@!\>\|when\|\%(\%(^\|;\)\s*\)\@<=\<in\|elsif\):\@!\>'

# Regex that defines the end-match for the 'end' keyword.
var end_end_regex = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'

# Expression used for searchpair() call for finding a match for an 'end' keyword.
def EndSkipExpr(): bool
  if eval(skip_expr)
    return 1
  elseif expand('<cword>') == 'do'
        \ && getline(".") =~ '^\s*\<\(while\|until\|for\):\@!\>'
    return 1
  elseif getline('.') =~ ruby_endless_def
    return 1
  elseif getline('.') =~ '\<def\s\+\k\+[!?]\=([^)]*$'
    # Then it's a `def method(` with a possible `) =` later
    call search('\<def\s\+\k\+\zs(', 'W', line('.'))
    normal! %
    return getline('.') =~ ')\s*='
  else
    return 0
  endif
enddef

# Regex that defines continuation lines, not including (, {, or [.
var non_bracket_continuation_regex =
      \ '\%([\\.,:*/%+]\|\<and\|\<or\|\%(<%\)\@<![=-]\|:\@<![^[:alnum:]:][|&?]\|||\|&&\)\s*\%(#.*\)\=$'

# Regex that defines continuation lines.
var continuation_regex =
      \ '\%(%\@<![({[\\.,:*/%+]\|\<and\|\<or\|\%(<%\)\@<![=-]\|:\@<![^[:alnum:]:][|&?]\|||\|&&\)\s*\%(#.*\)\=$'

# Regex that defines continuable keywords
var continuable_regex =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' ..
      \ '\<\%(if\|for\|while\|until\|unless\):\@!\>'

# Regex that defines bracket continuations
var bracket_continuation_regex = '%\@<!\%([({[]\)\s*\%(#.*\)\=$'

# Regex that defines dot continuations
var dot_continuation_regex = '%\@<!\.\s*\%(#.*\)\=$'

# Regex that defines backslash continuations
var backslash_continuation_regex = '%\@<!\\\s*$'

# Regex that defines end of bracket continuation followed by another continuation
var bracket_switch_continuation_regex = '^\([^(]\+\zs).\+\)\+' .. continuation_regex

# Regex that defines the first part of a splat pattern
var splat_regex = '[[,(]\s*\*\s*\%(#.*\)\=$'

# Regex that describes all indent access modifiers
var access_modifier_regex = '\C^\s*\%(public\|protected\|private\)\s*\%(#.*\)\=$'

# Regex that describes the indent access modifiers (excludes public)
var indent_access_modifier_regex = '\C^\s*\%(protected\|private\)\s*\%(#.*\)\=$'

# Regex that defines blocks.
#
# Note that there's a slight problem with this regex and continuation_regex.
# Code like this will be matched by both:
#
#   method_call do |(a, b)|
#
# The reason is that the pipe matches a hanging "|" operator.
#
var block_regex =
      \ '\%(\<do:\@!\>\|%\@<!{\)\s*\%(|[^|]*|\)\=\s*\%(#.*\)\=$'

var block_continuation_regex = '^\s*[^])}\t ].*' .. block_regex

# Regex that describes a leading operator (only a method call's dot for now)
var leading_operator_regex = '^\s*\%(&\=\.\)'

# 3. Indenting Logic Callbacks {{{1
# ============================

def AccessModifier(cline_info: dict<any>): number
  var info = cline_info

  # If this line is an access modifier keyword, align according to the closest
  # class declaration.
  if g:ruby_indent_access_modifier_style == 'indent'
    if IsMatch(info.clnum, access_modifier_regex)
      var class_lnum = FindContainingClass()
      if class_lnum > 0
        return indent(class_lnum) + info.sw
      endif
    endif
  elseif g:ruby_indent_access_modifier_style == 'outdent'
    if IsMatch(info.clnum, access_modifier_regex)
      var class_lnum = FindContainingClass()
      if class_lnum > 0
        return indent(class_lnum)
      endif
    endif
  endif

  return -1
enddef

def ClosingBracketOnEmptyLine(cline_info: dict<any>): number
  var info = cline_info

  # If we got a closing bracket on an empty line, find its match and indent
  # according to it.  For parentheses we indent to its column - 1, for the
  # others we indent to the containing line's MSL's level.  Return -1 if fail.
  var col = matchend(info.cline, '^\s*[]})]')

  if col > 0 && !IsInStringOrComment(info.clnum, col)
    call cursor(info.clnum, col)
    var closing_bracket = info.cline[col - 1]
    var bracket_pair = strpart('(){}[]', stridx(')}]', closing_bracket) * 2, 2)
    var ind = -1

    if searchpair(escape(bracket_pair[0], '\['), '', bracket_pair[1], 'bW', skip_expr) > 0
      if closing_bracket == ')' && col('.') != col('$') - 1
        if g:ruby_indent_hanging_elements
          ind = virtcol('.') - 1
        else
          ind = indent(line('.'))
        endif
      elseif g:ruby_indent_block_style == 'do'
        ind = indent(line('.'))
      else # g:ruby_indent_block_style == 'expression'
        ind = indent(GetMSL(line('.')))
      endif
    endif

    return ind
  endif

  return -1
enddef

def BlockComment(cline_info: dict<any>): number
  # If we have a =begin or =end set indent to first column.
  if match(cline_info.cline, '^\s*\%(=begin\|=end\)$') != -1
    return 0
  endif
  return -1
enddef

def DeindentingKeyword(cline_info: dict<any>): number
  var info = cline_info

  # If we have a deindenting keyword, find its match and indent to its level.
  # TODO: this is messy
  if IsMatch(info.clnum, ruby_deindent_keywords)
    var ind = -1
    call cursor(info.clnum, 1)

    if searchpair(end_start_regex, end_middle_regex, end_end_regex, 'bW',
          \ EndSkipExpr) > 0
      var msl  = GetMSL(line('.'))
      var line = getline(line('.'))

      if IsAssignment(line, col('.')) &&
            \ strpart(line, col('.') - 1, 2) !~ 'do'
        # assignment to case/begin/etc, on the same line
        if g:ruby_indent_assignment_style == 'hanging'
          # hanging indent
          ind = virtcol('.') - 1
        else
          # align with variable
          ind = indent(line('.'))
        endif
      elseif g:ruby_indent_block_style == 'do'
        # align to line of the "do", not to the MSL
        ind = indent(line('.'))
      elseif getline(msl) =~ '=\s*\(#.*\)\=$'
        # in the case of assignment to the MSL, align to the starting line,
        # not to the MSL
        ind = indent(line('.'))
      else
        # align to the MSL
        ind = indent(msl)
      endif
    endif
    return ind
  endif

  return -1
enddef

def MultilineStringOrLineComment(cline_info: dict<any>): number
  var info = cline_info

  # If we are in a multi-line string or line-comment, don't do anything to it.
  if IsInStringOrDocumentation(info.clnum, matchend(info.cline, '^\s*') + 1)
    return indent(info.clnum)
  endif
  return -1
enddef

def ClosingHeredocDelimiter(cline_info: dict<any>): number
  var info = cline_info

  # If we are at the closing delimiter of a "<<" heredoc-style string, set the
  # indent to 0.
  if info.cline =~ '^\k\+\s*$'
        \ && IsInStringDelimiter(info.clnum, 1)
        \ && search('\V<<' .. info.cline, 'nbW') > 0
    return 0
  endif

  return -1
enddef

def LeadingOperator(cline_info: dict<any>): number
  # If the current line starts with a leading operator, add a level of indent.
  if IsMatch(cline_info.clnum, leading_operator_regex)
    return indent(GetMSL(cline_info.clnum)) + cline_info.sw
  endif
  return -1
enddef

def EmptyInsideString(pline_info: dict<any>): number
  # If the line is empty and inside a string (the previous line is a string,
  # too), use the previous line's indent
  var info = pline_info

  var plnum = prevnonblank(info.clnum - 1)
  var pline = getline(plnum)

  if info.cline =~ '^\s*$'
        \ && IsInStringOrComment(plnum, 1)
        \ && IsInStringOrComment(plnum, strlen(pline))
    return indent(plnum)
  endif
  return -1
enddef

def StartOfFile(pline_info: dict<any>): number
  # At the start of the file use zero indent.
  if pline_info.plnum == 0
    return 0
  endif
  return -1
enddef

def AfterAccessModifier(pline_info: dict<any>): number
  var info = pline_info

  if g:ruby_indent_access_modifier_style == 'indent'
    # If the previous line was a private/protected keyword, add a
    # level of indent.
    if IsMatch(info.plnum, indent_access_modifier_regex)
      return indent(info.plnum) + info.sw
    endif
  elseif g:ruby_indent_access_modifier_style == 'outdent'
    # If the previous line was a private/protected/public keyword, add
    # a level of indent, since the keyword has been out-dented.
    if IsMatch(info.plnum, access_modifier_regex)
      return indent(info.plnum) + info.sw
    endif
  endif
  return -1
enddef

# Example:
#
#   if foo || bar ||
#       baz || bing
#     puts "foo"
#   end
#
def ContinuedLine(pline_info: dict<any>): number
  var info = pline_info

  var col = Match(info.plnum, ruby_indent_keywords)
  if IsMatch(info.plnum, continuable_regex) &&
        \ IsMatch(info.plnum, continuation_regex)
    var ind = -1
    if col > 0 && IsAssignment(info.pline, col)
      if g:ruby_indent_assignment_style == 'hanging'
        # hanging indent
        ind = col - 1
      else
        # align with variable
        ind = indent(info.plnum)
      endif
    else
      ind = indent(GetMSL(info.plnum))
    endif
    return ind + info.sw + info.sw
  endif
  return -1
enddef

def AfterBlockOpening(pline_info: dict<any>): number
  var info = pline_info

  # If the previous line ended with a block opening, add a level of indent.
  if IsMatch(info.plnum, block_regex)
    var ind = -1

    if g:ruby_indent_block_style == 'do'
      # don't align to the msl, align to the "do"
      ind = indent(info.plnum) + info.sw
    else
      var plnum_msl = GetMSL(info.plnum)

      if getline(plnum_msl) =~ '=\s*\(#.*\)\=$'
        # in the case of assignment to the msl, align to the starting line,
        # not to the msl
        ind = indent(info.plnum) + info.sw
      else
        ind = indent(plnum_msl) + info.sw
      endif
    endif

    return ind
  endif

  return -1
enddef

def AfterLeadingOperator(pline_info: dict<any>): number
  # If the previous line started with a leading operator, use its MSL's level
  # of indent
  if IsMatch(pline_info.plnum, leading_operator_regex)
    return indent(GetMSL(pline_info.plnum))
  endif
  return -1
enddef

def AfterHangingSplat(pline_info: dict<any>): number
  var info = pline_info

  # If the previous line ended with the "*" of a splat, add a level of indent
  if info.pline =~ splat_regex
    return indent(info.plnum) + info.sw
  endif
  return -1
enddef

def AfterUnbalancedBracket(pline_info: dict<any>): number
  var info = pline_info

  # If the previous line contained unclosed opening brackets and we are still
  # in them, find the rightmost one and add indent depending on the bracket
  # type.
  #
  # If it contained hanging closing brackets, find the rightmost one, find its
  # match and indent according to that.
  if info.pline =~ '[[({]' || info.pline =~ '[])}]\s*\%(#.*\)\=$'
    var brackets = ExtraBrackets(info.plnum)
    var opening = brackets[0]
    var closing = brackets[1]

    if opening.pos != -1
      if !g:ruby_indent_hanging_elements
        return indent(info.plnum) + info.sw
      elseif opening.type == '(' && searchpair('(', '', ')', 'bW', skip_expr) > 0
        if col('.') + 1 == col('$')
          return indent(info.plnum) + info.sw
        else
          return virtcol('.')
        endif
      else
        var nonspace = matchend(info.pline, '\S', opening.pos + 1) - 1
        return nonspace > 0 ? nonspace : indent(info.plnum) + info.sw
      endif
    elseif closing.pos != -1
      call cursor(info.plnum, closing.pos + 1)
      normal! %

      if strpart(info.pline, closing.pos) =~ '^)\s*='
        # special case: the closing `) =` of an endless def
        return indent(GetMSL(line('.')))
      endif

      if IsMatch(line('.'), ruby_indent_keywords)
        return indent('.') + info.sw
      else
        return indent(GetMSL(line('.')))
      endif
    else
      call cursor(info.clnum, info.col)
    endif
  endif

  return -1
enddef

def AfterEndKeyword(pline_info: dict<any>): number
  var info = pline_info
  # If the previous line ended with an "end", match that "end"s beginning's
  # indent.
  var col = Match(info.plnum, '\%(^\|[^.:@$]\)\<end\>\s*\%(#.*\)\=$')
  if col > 0
    call cursor(info.plnum, col)
    if searchpair(end_start_regex, '', end_end_regex, 'bW',
          \ EndSkipExpr) > 0
      var n = line('.')
      var ind = indent('.')
      var msl = GetMSL(n)
      if msl != n
        ind = indent(msl)
      endif
      return ind
    endif
  endif
  return -1
enddef

def AfterIndentKeyword(pline_info: dict<any>): number
  var info = pline_info
  var col = Match(info.plnum, ruby_indent_keywords)

  if col > 0 && Match(info.plnum, ruby_endless_def) <= 0
    call cursor(info.plnum, col)
    var ind = virtcol('.') - 1 + info.sw
    # TODO: make this better (we need to count them) (or, if a searchpair
    # fails, we know that something is lacking an end and thus we indent a
    # level
    if IsMatch(info.plnum, end_end_regex)
      ind = indent('.')
    elseif IsAssignment(info.pline, col)
      if g:ruby_indent_assignment_style == 'hanging'
        # hanging indent
        ind = col + info.sw - 1
      else
        # align with variable
        ind = indent(info.plnum) + info.sw
      endif
    endif
    return ind
  endif

  return -1
enddef

def PreviousNotMSL(msl_info: dict<any>): number
  var info = msl_info

  # If the previous line wasn't a MSL
  if info.plnum != info.plnum_msl
    # If previous line ends bracket and begins non-bracket continuation decrease indent by 1.
    if IsMatch(info.plnum, bracket_switch_continuation_regex)
      # TODO (2016-10-07) Wrong/unused? How could it be "1"?
      return indent(info.plnum) - 1
      # If previous line is a continuation return its indent.
    elseif IsMatch(info.plnum, non_bracket_continuation_regex)
      return indent(info.plnum)
    endif
  endif

  return -1
enddef

def IndentingKeywordInMSL(msl_info: dict<any>): number
  var info = msl_info
  # If the MSL line had an indenting keyword in it, add a level of indent.
  # TODO: this does not take into account contrived things such as
  # module Foo; class Bar; end
  var col = Match(info.plnum_msl, ruby_indent_keywords)
  if col > 0 && Match(info.plnum_msl, ruby_endless_def) <= 0
    var ind = indent(info.plnum_msl) + info.sw
    if IsMatch(info.plnum_msl, end_end_regex)
      ind = ind - info.sw
    elseif IsAssignment(getline(info.plnum_msl), col)
      if g:ruby_indent_assignment_style == 'hanging'
        # hanging indent
        ind = col + info.sw - 1
      else
        # align with variable
        ind = indent(info.plnum_msl) + info.sw
      endif
    endif
    return ind
  endif
  return -1
enddef

def ContinuedHangingOperator(msl_info: dict<any>): number
  var info = msl_info

  # If the previous line ended with [*+/.,-=], but wasn't a block ending or a
  # closing bracket, indent one extra level.
  if IsMatch(info.plnum_msl, non_bracket_continuation_regex) && !IsMatch(info.plnum_msl, '^\s*\([\])}]\|end\)')
    var ind = -1
    if info.plnum_msl == info.plnum
      ind = indent(info.plnum_msl) + info.sw
    else
      ind = indent(info.plnum_msl)
    endif
    return ind
  endif

  return -1
enddef

# 4. Auxiliary Functions {{{1
# ======================

def IsInRubyGroup(groups: list<string>, lnum: number, col: number): bool
  var ids = mapnew(copy(groups), 'hlID("ruby" .. v:val)')
  return index(ids, synID(lnum, col, 1)) >= 0
enddef

# Check if the character at lnum:col is inside a string, comment, or is ascii.
def IsInStringOrComment(lnum: number, col: number): bool
  return IsInRubyGroup(syng_strcom, lnum, col)
enddef

# Check if the character at lnum:col is inside a string.
def IsInString(lnum: number, col: number): bool
  return IsInRubyGroup(syng_string, lnum, col)
enddef

# Check if the character at lnum:col is inside a string or documentation.
def IsInStringOrDocumentation(lnum: number, col: number): bool
  return IsInRubyGroup(syng_stringdoc, lnum, col)
enddef

# Check if the character at lnum:col is inside a string delimiter
def IsInStringDelimiter(lnum: number, col: number): bool
  return IsInRubyGroup(
        \ ['HeredocDelimiter', 'PercentStringDelimiter', 'StringDelimiter'],
        \ lnum, col
        \ )
enddef

def IsAssignment(str: string, pos: number): bool
  return strpart(str, 0, pos - 1) =~ '=\s*$'
enddef

# Find line above 'lnum' that isn't empty, in a comment, or in a string.
def PrevNonBlankNonString(a_lnum: number): number
  var in_block = 0
  var lnum = prevnonblank(a_lnum)
  while lnum > 0
    # Go in and out of blocks comments as necessary.
    # If the line isn't empty (with opt. comment) or in a string, end search.
    var line = getline(lnum)
    if line =~ '^=begin'
      if in_block
        in_block = 0
      else
        break
      endif
    elseif !in_block && line =~ '^=end'
      in_block = 1
    elseif !in_block && line !~ '^\s*#.*$' && !(IsInStringOrComment(lnum, 1)
          \ && IsInStringOrComment(lnum, strlen(line)))
      break
    endif
    lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
enddef

# Find line above 'lnum' that started the continuation 'lnum' may be part of.
def GetMSL(a_lnum: number): number
  # Start on the line we're at and use its indent.
  var msl = a_lnum
  var lnum = PrevNonBlankNonString(a_lnum - 1)
  while lnum > 0
    # If we have a continuation line, or we're in a string, use line as MSL.
    # Otherwise, terminate search as we have found our MSL already.
    var line = getline(lnum)

    # TODO number as boolean

    if !IsMatch(msl, backslash_continuation_regex) &&
          \ IsMatch(lnum, backslash_continuation_regex)
      # If the current line doesn't end in a backslash, but the previous one
      # does, look for that line's msl
      #
      # Example:
      #   foo = "bar" \
      #     "baz"
      #
      msl = lnum
    elseif IsMatch(msl, leading_operator_regex)
      # If the current line starts with a leading operator, keep its indent
      # and keep looking for an MSL.
      msl = lnum
    elseif IsMatch(lnum, splat_regex)
      # If the above line looks like the "*" of a splat, use the current one's
      # indentation.
      #
      # Example:
      #   Hash[*
      #     method_call do
      #       something
      #
      return msl
    elseif IsMatch(lnum, non_bracket_continuation_regex) &&
          \ IsMatch(msl, non_bracket_continuation_regex)
      # If the current line is a non-bracket continuation and so is the
      # previous one, keep its indent and continue looking for an MSL.
      #
      # Example:
      #   method_call one,
      #     two,
      #     three
      #
      msl = lnum
    elseif IsMatch(lnum, dot_continuation_regex) &&
          \ (IsMatch(msl, bracket_continuation_regex) || IsMatch(msl, block_continuation_regex))
      # If the current line is a bracket continuation or a block-starter, but
      # the previous is a dot, keep going to see if the previous line is the
      # start of another continuation.
      #
      # Example:
      #   parent.
      #     method_call {
      #     three
      #
      msl = lnum
    elseif IsMatch(lnum, non_bracket_continuation_regex) &&
          \ (IsMatch(msl, bracket_continuation_regex) || IsMatch(msl, block_continuation_regex))
      # If the current line is a bracket continuation or a block-starter, but
      # the previous is a non-bracket one, respect the previous' indentation,
      # and stop here.
      #
      # Example:
      #   method_call one,
      #     two {
      #     three
      #
      return lnum
    elseif IsMatch(lnum, bracket_continuation_regex) &&
          \ (IsMatch(msl, bracket_continuation_regex) || IsMatch(msl, block_continuation_regex))
      # If both lines are bracket continuations (the current may also be a
      # block-starter), use the current one's and stop here
      #
      # Example:
      #   method_call(
      #     other_method_call(
      #       foo
      return msl
    elseif IsMatch(lnum, block_regex) &&
          \ !IsMatch(msl, continuation_regex) &&
          \ !IsMatch(msl, block_continuation_regex)
      # If the previous line is a block-starter and the current one is
      # mostly ordinary, use the current one as the MSL.
      #
      # Example:
      #   method_call do
      #     something
      #     something_else
      return msl
    else
      var col = match(line, continuation_regex) + 1
      if (col > 0 && !IsInStringOrComment(lnum, col))
            \ || IsInString(lnum, strlen(line))
        msl = lnum
      else
        break
      endif
    endif

    lnum = PrevNonBlankNonString(lnum - 1)
  endwhile
  return msl
enddef

# Check if line 'lnum' has more opening brackets than closing ones.
def ExtraBrackets(lnum: number): list<dict<any>>
  var opening: dict<list<dict<any>>> = {'parentheses': [], 'braces': [], 'brackets': []}
  var closing: dict<list<dict<any>>> = {'parentheses': [], 'braces': [], 'brackets': []}

  var line = getline(lnum)
  var pos  = match(line, '[][(){}]', 0)

  # Save any encountered opening brackets, and remove them once a matching
  # closing one has been found. If a closing bracket shows up that doesn't
  # close anything, save it for later.
  while pos != -1
    if !IsInStringOrComment(lnum, pos + 1)
      if line[pos] == '('
        call add(opening.parentheses, {'type': '(', 'pos': pos})
      elseif line[pos] == ')'
        if empty(opening.parentheses)
          call add(closing.parentheses, {'type': ')', 'pos': pos})
        else
          opening.parentheses = opening.parentheses[0 : -2]
        endif
      elseif line[pos] == '{'
        call add(opening.braces, {'type': '{', 'pos': pos})
      elseif line[pos] == '}'
        if empty(opening.braces)
          call add(closing.braces, {'type': '}', 'pos': pos})
        else
          opening.braces = opening.braces[0 : -2]
        endif
      elseif line[pos] == '['
        call add(opening.brackets, {'type': '[', 'pos': pos})
      elseif line[pos] == ']'
        if empty(opening.brackets)
          call add(closing.brackets, {'type': ']', 'pos': pos})
        else
          opening.brackets = opening.brackets[0 : -2]
        endif
      endif
    endif

    pos = match(line, '[][(){}]', pos + 1)
  endwhile

  # Find the rightmost brackets, since they're the ones that are important in
  # both opening and closing cases
  var rightmost_opening = {'type': '(', 'pos': -1}
  var rightmost_closing = {'type': ')', 'pos': -1}

  for local_opening in opening.parentheses + opening.braces + opening.brackets
    if local_opening.pos > rightmost_opening.pos
      rightmost_opening = local_opening
    endif
  endfor

  for local_closing in closing.parentheses + closing.braces + closing.brackets
    if local_closing.pos > rightmost_closing.pos
      rightmost_closing = local_closing
    endif
  endfor

  return [rightmost_opening, rightmost_closing]
enddef

def Match(lnum: number, regex: string): number
  var line   = getline(lnum)
  var offset = match(line, '\C' .. regex)
  var col    = offset + 1

  while offset > -1 && IsInStringOrComment(lnum, col)
    offset = match(line, '\C' .. regex, offset + 1)
    col = offset + 1
  endwhile

  if offset > -1
    return col
  else
    return 0
  endif
enddef

def IsMatch(lnum: number, regex: string): bool
  return Match(lnum, regex) > 0
enddef

# Locates the containing class/module's definition line, ignoring nested classes
# along the way.
#
def FindContainingClass(): number
  var saved_position = getpos('.')

  while searchpair(end_start_regex, end_middle_regex, end_end_regex, 'bW',
        \ EndSkipExpr) > 0
    if expand('<cword>') =~# '\<class\|module\>'
      var found_lnum = line('.')
      call setpos('.', saved_position)
      return found_lnum
    endif
  endwhile

  call setpos('.', saved_position)
  return 0
enddef

# }}}1

# 2. GetRubyIndent Function {{{1
# =========================

export def GetRubyIndent(lnum: number): number
  # 2.1. Setup {{{2
  # ----------

  var indent_info = {}

  # The value of a single shift-width
  if exists('*shiftwidth')
    indent_info.sw = shiftwidth()
  else
    indent_info.sw = &sw
  endif

  # For the current line, use the first argument if given, else v:lnum
  indent_info.clnum = lnum
  indent_info.cline = getline(indent_info.clnum)

  # Set up variables for restoring position in file.  Could use clnum here.
  indent_info.col = col('.')

  # 2.2. Work on the current line {{{2
  # -----------------------------
  var indent_callback_names = [
        \ 'AccessModifier',
        \ 'ClosingBracketOnEmptyLine',
        \ 'BlockComment',
        \ 'DeindentingKeyword',
        \ 'MultilineStringOrLineComment',
        \ 'ClosingHeredocDelimiter',
        \ 'LeadingOperator',
        \ ]

  for callback_name in indent_callback_names
    #    Decho "Running: ".callback_name
    var indent = call(function(callback_name), [indent_info])

    if indent >= 0
      #      Decho "Match: ".callback_name." indent=".indent." info=".string(indent_info)
      return indent
    endif
  endfor

  # 2.3. Work on the previous line. {{{2
  # -------------------------------

  # Special case: we don't need the real PrevNonBlankNonString for an empty
  # line inside a string. And that call can be quite expensive in that
  # particular situation.
  indent_callback_names = [
        \ 'EmptyInsideString',
        \ ]

  for callback_name in indent_callback_names
    #    Decho "Running: ".callback_name
    var indent = call(function(callback_name), [indent_info])

    if indent >= 0
      #      Decho "Match: ".callback_name." indent=".indent." info=".string(indent_info)
      return indent
    endif
  endfor

  # Previous line number
  indent_info.plnum = PrevNonBlankNonString(indent_info.clnum - 1)
  indent_info.pline = getline(indent_info.plnum)

  indent_callback_names = [
        \ 'StartOfFile',
        \ 'AfterAccessModifier',
        \ 'ContinuedLine',
        \ 'AfterBlockOpening',
        \ 'AfterHangingSplat',
        \ 'AfterUnbalancedBracket',
        \ 'AfterLeadingOperator',
        \ 'AfterEndKeyword',
        \ 'AfterIndentKeyword',
        \ ]

  for callback_name in indent_callback_names
    #    Decho "Running: ".callback_name
    var indent = call(function(callback_name), [indent_info])

    if indent >= 0
      #      Decho "Match: ".callback_name." indent=".indent." info=".string(indent_info)
      return indent
    endif
  endfor

  # 2.4. Work on the MSL line. {{{2
  # --------------------------
  indent_callback_names = [
        \ 'PreviousNotMSL',
        \ 'IndentingKeywordInMSL',
        \ 'ContinuedHangingOperator',
        \ ]

  # Most Significant line based on the previous one -- in case it's a
  # continuation of something above
  indent_info.plnum_msl = GetMSL(indent_info.plnum)

  for callback_name in indent_callback_names
    #    Decho "Running: ".callback_name
    var indent = call(function(callback_name), [indent_info])

    if indent >= 0
      #      Decho "Match: ".callback_name." indent=".indent." info=".string(indent_info)
      return indent
    endif
  endfor

  # }}}2

  # By default, just return the previous line's indent
  #  Decho "Default case matched"
  return indent(indent_info.plnum)
enddef

defcompile

# vim:set sw=2 sts=2 ts=8 et:
