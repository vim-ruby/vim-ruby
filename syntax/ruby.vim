" Vim syntax file
" Language:	Ruby
" Maintainer:	Doug Kearns <djkea2 at mugca.its.monash.edu.au>
" Info:		$Id: ruby.vim,v 1.32 2003/10/03 11:06:35 dkearns Exp $
" URL:		http://vim-ruby.sourceforge.net
" Anon CVS:	See above site
" Licence:	GPL (http://www.gnu.org)
" Disclaimer:
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" ----------------------------------------------------------------------------
"
" Previous Maintainer:	Mirko Nasato
" Thanks to perl.vim authors, and to Reimer Behrends. :-) (MN)
" ----------------------------------------------------------------------------

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Expression Substitution and Backslash Notation
syn match rubyEscape		"\\\\\|\\[abefnrstv]\|\\\o\{1,3}\|\\x\x\{1,2}"								contained display
syn match rubyEscape		"\%(\\M-\\C-\|\\C-\\M-\|\\M-\\c\|\\c\\M-\|\\c\|\\C-\|\\M-\)\%(\\\o\{1,3}\|\\x\x\{1,2}\|\\\=\S\)"	contained display
syn match rubyInterpolation	"#{[^}]*}"				contained
syn match rubyInterpolation	"#\%(\$\|@@\=\)\w\+"			contained display
syn match rubyNoInterpolation	"\\#{[^}]*}"				contained
syn match rubyNoInterpolation	"\\#\%(\$\|@@\=\)\w\+"			contained display

syn cluster rubyStringSpecial contains=rubyInterpolation,rubyNoInterpolation,rubyEscape

" Numbers and ASCII Codes
syn match rubyASCIICode	"\w\@<!\%(?\%(\\M-\\C-\|\\C-\\M-\|\\M-\\c\|\\c\\M-\|\\c\|\\C-\|\\M-\)\=\%(\\\o\{1,3}\|\\x\x\{1,2}\|\\\=\S\)\)"
syn match rubyInteger	"\<0x\x\+\%(_\x\+\)*\>"									display
syn match rubyInteger	"\<\%(0\|[1-9]\d*\%(_\d\+\)*\)\>"							display
syn match rubyInteger	"\<0\o\+\%(_\o\+\)*\>"									display
syn match rubyInteger	"\<0b[01]\+\%(_[01]\+\)*\>"								display
syn match rubyFloat	"\<\%(0\|[1-9]\d*\%(_\d\+\)*\)\.\d\+\%(_\d\+\)*\>"					display
syn match rubyFloat	"\<\%(0\|[1-9]\d*\%(_\d\+\)*\)\%(\.\d\+\%(_\d\+\)*\)\=\%([eE][-+]\=\d\+\%(_\d\+\)*\)\>"	display

" Identifiers
syn match rubyLocalVariableOrMethod "[_[:lower:]][_[:alnum:]]*[?!=]\=" contains=NONE display transparent

if !exists("ruby_no_identifiers")
  syn match  rubyConstant		"\%(::\)\=\zs\u\w*"	display
  syn match  rubyClassVariable		"@@\h\w*"		display
  syn match  rubyInstanceVariable	"@\h\w*"		display
  syn match  rubyGlobalVariable		"$\%(\h\w*\|-.\)"
  syn match  rubySymbol			":\@<!:\%(\^\|\~\|<<\|<=>\|<=\|<\|===\|==\|=\~\|>>\|>=\|>\||\|-@\|-\|/\|\[]=\|\[]\|\*\*\|\*\|&\|%\|+@\|+\|`\)"
  syn match  rubySymbol			":\@<!:\$\%(-.\|[`~<=>_,;:!?/.'"@$*\&+0]\)"
  syn match  rubySymbol			":\@<!:\%(\$\|@@\=\)\=\h\w*[?!=]\="
  syn region rubySymbol			start=":\@<!:\"" end="\"" skip="\\\\\|\\\""
  syn match  rubyIterator		"|[ ,a-zA-Z0-9_*]\+|"	display

  syn match rubyPredefinedVariable "$[!"$&'*+,./0:;<=>?@\_`~1-9]"
  syn match rubyPredefinedVariable "$-[0FIKadilpvw]"									display
  syn match rubyPredefinedVariable "$\%(deferr\|defout\|stderr\|stdin\|stdout\)\>"					display
  syn match rubyPredefinedVariable "$\%(DEBUG\|FILENAME\|KCODE\|LOAD_PATH\|SAFE\|VERBOSE\)\>"				display
  syn match rubyPredefinedConstant "\<\%(::\)\=\zs\%(MatchingData\|ARGF\|ARGV\|ENV\)\>"					display
  syn match rubyPredefinedConstant "\<\%(::\)\=\zs\%(DATA\|FALSE\|NIL\|RUBY_PLATFORM\|RUBY_RELEASE_DATE\)\>"		display
  syn match rubyPredefinedConstant "\<\%(::\)\=\zs\%(RUBY_VERSION\|STDERR\|STDIN\|STDOUT\|TOPLEVEL_BINDING\|TRUE\)\>"	display
  "Obsolete Global Constants
  "syn match rubyPredefinedConstant "\<\%(::\)\=\zs\%(PLATFORM\|RELEASE_DATE\|VERSION\)\>"
  "syn match rubyPredefinedConstant "\<\%(::\)\=\zs\%(NotImplementError\)\>"
endif

" Normal Regular Expression
syn region rubyString matchgroup=rubyStringDelimiter start="^\s*/" start="\<and\s*/"lc=3 start="\<or\s*/"lc=2 start="\<while\s*/"lc=5 start="\<until\s*/"lc=5 start="\<unless\s*/"lc=6 start="\<if\s*/"lc=2 start="\<elsif\s*/"lc=5 start="\<when\s*/"lc=4 start="\<not\s*/"lc=3  start="\<then\s*/"lc=4 start="[\~=!|&(,[]\s*/"lc=1 end="/[iomx]*" skip="\\\\\|\\/" contains=@rubyStringSpecial
syn region rubyString matchgroup=rubyStringDelimiter start="\<split\s*/"lc=5 start="\<\%(scan\|gsub\)\s*/"lc=4 start="\<sub\s*/"lc=3 end="/[iomx]*" skip="\\\\\|\\/" contains=@rubyStringSpecial

" Normal String and Shell Command Output
syn region rubyString matchgroup=rubyStringDelimiter start="\"" end="\"" skip="\\\\\|\\\"" contains=@rubyStringSpecial
syn region rubyString matchgroup=rubyStringDelimiter start="'"  end="'"  skip="\\\\\|\\'"
syn region rubyString matchgroup=rubyStringDelimiter start="`"  end="`"  skip="\\\\\|\\`"  contains=@rubyStringSpecial

" Generalized Regular Expression
syn region rubyString matchgroup=rubyStringDelimiter start="%r\z([~`!@#$%^&*_\-+=|\:;"',.?/]\)"	end="\z1[iomx]*" skip="\\\\\|\\\z1" contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%r{"				end="}[iomx]*"	 skip="\\\\\|\\}"   contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%r<"				end=">[iomx]*"	 skip="\\\\\|\\>"   contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%r\["				end="\][iomx]*"	 skip="\\\\\|\\\]"  contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%r("				end=")[iomx]*"	 skip="\\\\\|\\)"   contains=@rubyStringSpecial fold

" Generalized Single Quoted String, Symbol and Array of Strings
syn region rubyString matchgroup=rubyStringDelimiter start="%[qsw]\z([~`!@#$%^&*_\-+=|\:;"',.?/]\)" end="\z1" skip="\\\\\|\\\z1" fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[qsw]{"				    end="}"   skip="\\\\\|\\}"	 fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[qsw]<"				    end=">"   skip="\\\\\|\\>"	 fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[qsw]\["				    end="\]"  skip="\\\\\|\\\]"	 fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[qsw]("				    end=")"   skip="\\\\\|\\)"	 fold

" Generalized Double Quoted String and Array of Strings and Shell Command Output
" Note: %= is not matched here as the beginning of a double quoted string
syn region rubyString matchgroup=rubyStringDelimiter start="%\z([~`!@#$%^&*_\-+|\:;"',.?/]\)"	    end="\z1" skip="\\\\\|\\\z1" contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[QWx]\z([~`!@#$%^&*_\-+=|\:;"',.?/]\)" end="\z1" skip="\\\\\|\\\z1" contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[QWx]\={"				    end="}"   skip="\\\\\|\\}"	 contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[QWx]\=<"				    end=">"   skip="\\\\\|\\>"	 contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[QWx]\=\["				    end="\]"  skip="\\\\\|\\\]"	 contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start="%[QWx]\=("				    end=")"   skip="\\\\\|\\)"	 contains=@rubyStringSpecial fold

" Here Document
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<\z(\h\w*\)\ze\s*$+hs=s+2 end=+^\z1$+ contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<"\z(.*\)"\ze\s*$+hs=s+2  end=+^\z1$+ contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<'\z(.*\)'\ze\s*$+hs=s+2  end=+^\z1$+			      fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<`\z(.*\)`\ze\s*$+hs=s+2  end=+^\z1$+ contains=@rubyStringSpecial fold

syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<-\z(\h\w*\)\ze\s*$+hs=s+3 end=+^\s*\zs\z1$+ contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<-"\z(.*\)"\ze\s*$+hs=s+3  end=+^\s*\zs\z1$+ contains=@rubyStringSpecial fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<-'\z(.*\)'\ze\s*$+hs=s+3  end=+^\s*\zs\z1$+			     fold
syn region rubyString matchgroup=rubyStringDelimiter start=+\%(\%(class\s*\|\%(\.\|::\)\)\_s*\)\@<!<<-`\z(.*\)`\ze\s*$+hs=s+3  end=+^\s*\zs\z1$+ contains=@rubyStringSpecial fold

" Expensive Mode - colorize *end* according to opening statement
if !exists("ruby_no_expensive")
  syn region rubyFunction matchgroup=rubyDefine start="\<def\s\+"    end="\ze\%(\s\|(\|;\|$\)" oneline
  syn region rubyClass    matchgroup=rubyDefine start="\<class\s\+"  end="\ze\%(\s\|<\|;\|$\)" oneline
  syn match  rubyDefine   "\<class\ze<<"
  syn region rubyModule   matchgroup=rubyDefine start="\<module\s\+" end="\ze\%(\s\|;\|$\)"    oneline

  syn region rubyBlock start="\<def\>"    matchgroup=rubyDefine end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo nextgroup=rubyFunction fold
  syn region rubyBlock start="\<class\>"  matchgroup=rubyDefine end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo nextgroup=rubyClass    fold
  syn region rubyBlock start="\<module\>" matchgroup=rubyDefine end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo nextgroup=rubyModule   fold

  " modifiers
  syn match  rubyControl "\<\%(if\|unless\|while\|until\)\>" display

  " *do* requiring *end*
  syn region rubyDoBlock matchgroup=rubyControl start="\%(\<\%(for\|until\|while\)\s.*\s\)\@<!do\>" end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo fold

  " *{* requiring *}*
  syn region rubyCurlyBlock start="{" end="}" contains=ALLBUT,@rubyStringSpecial,rubyTodo fold

  " statements without *do*
  syn region rubyNoDoBlock matchgroup=rubyControl start="\<\%(case\|begin\)\>" start="^\s*\%(if\|unless\)\>" start="[;=(]\s*\%(if\|unless\)\>"hs=s+1 end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo fold

  " statement with optional *do*
  syn region rubyOptDoBlock matchgroup=rubyControl start="\<for\>" start="^\s*\%(while\|until\)\>" start=";\s*\%(while\|until\)\>"hs=s+1 end="\<end\>" contains=ALLBUT,@rubyStringSpecial,rubyTodo fold

  " optional *do*
  syn match  rubyControl "\%(\<\%(for\|until\|while\)\s.*\s\)\@<=\%(do\|:\)\>"

  if !exists("ruby_minlines")
    let ruby_minlines = 50
  endif
  exec "syn sync minlines=" . ruby_minlines

else
  syn region  rubyFunction matchgroup=rubyControl start="\<def\s\+"    end="\ze\%(\s\|(\|;\|$\)" oneline
  syn region  rubyClass    matchgroup=rubyControl start="\<class\s\+"  end="\ze\%(\s\|<\|;\|$\)" oneline
  syn match   rubyControl  "\<class\ze<<"
  syn region  rubyModule   matchgroup=rubyControl start="\<module\s\+" end="\ze\%(\s\|;\|$\)"    oneline
  syn keyword rubyControl case begin do for if unless while until end
endif

" Keywords
" Note: the following keywords have already been defined:
" begin case class def do end for if module unless until while
syn keyword rubyControl		and break else elsif ensure in next not or redo rescue retry return then when
syn match   rubyOperator	"\<defined?" display
syn keyword rubyKeyword		alias super undef yield
syn keyword rubyBoolean		true false
syn keyword rubyPseudoVariable	nil self __FILE__ __LINE__
syn keyword rubyBeginEnd	BEGIN END

" Special Methods
if !exists("ruby_no_special_methods")
  syn keyword rubyAccess    public protected private
  syn keyword rubyAttribute attr attr_accessor attr_reader attr_writer
  syn keyword rubyControl   abort at_exit exit fork loop trap
  syn keyword rubyEval      eval class_eval instance_eval module_eval
  syn keyword rubyException raise fail catch throw
  syn keyword rubyInclude   autoload extend include load require
  syn keyword rubyKeyword   callcc caller lambda proc
endif

" Comments and Documentation
syn match   rubySharpBang     "\%^#!.*" display
syn keyword rubyTodo          FIXME NOTE TODO XXX contained
syn match   rubyComment       "#.*" contains=rubySharpBang,rubyTodo,@Spell
syn region  rubyDocumentation start="^=begin" end="^=end.*$" contains=rubyTodo,@Spell fold

" Note: this is a hack to prevent 'keywords' being highlighted as such when called as methods
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(alias\|and\|begin\|break\|case\|class\|def\|defined\|do\|else\)\>"			transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(elsif\|end\|ensure\|false\|for\|if\|in\|module\|next\|nil\)\>"			transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(not\|or\|redo\|rescue\|retry\|return\|self\|super\|then\|true\)\>"			transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(undef\|unless\|until\|when\|while\|yield\|BEGIN\|END\|__FILE__\|__LINE__\)\>"	transparent contains=NONE

syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(abort\|at_exit\|attr\|attr_accessor\|attr_reader\)\>"	transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(attr_writer\|autoload\|callcc\|catch\|caller\)\>"		transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(eval\|class_eval\|instance_eval\|module_eval\|exit\)\>"	transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(extend\|fail\|fork\|include\|lambda\)\>"			transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(load\|loop\|private\|proc\|protected\)\>"			transparent contains=NONE
syn match rubyKeywordAsMethod "\%(\%(\.\@<!\.\)\|::\)\_s*\%(public\|require\|raise\|throw\|trap\)\>"			transparent contains=NONE

" __END__ Directive
syn region rubyData matchgroup=rubyDataDirective start="^__END__$" end="\%$" fold

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_ruby_syntax_inits")
  if version < 508
    let did_ruby_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink rubyDefine			Define
  HiLink rubyFunction			Function
  HiLink rubyControl			Statement
  HiLink rubyInclude			Include
  HiLink rubyInteger			Number
  HiLink rubyASCIICode			rubyInteger
  HiLink rubyFloat			Float
  HiLink rubyBoolean			rubyPseudoVariable
  HiLink rubyException			Exception
  HiLink rubyClass			Type
  HiLink rubyModule			Type
  HiLink rubyIdentifier			Identifier
  HiLink rubyClassVariable		rubyIdentifier
  HiLink rubyConstant			rubyIdentifier
  HiLink rubyGlobalVariable		rubyIdentifier
  HiLink rubyIterator			rubyIdentifier
  HiLink rubyInstanceVariable		rubyIdentifier
  HiLink rubyPredefinedIdentifier	rubyIdentifier
  HiLink rubyPredefinedConstant		rubyPredefinedIdentifier
  HiLink rubyPredefinedVariable		rubyPredefinedIdentifier
  HiLink rubySymbol			rubyIdentifier
  HiLink rubyKeyword			Keyword
  HiLink rubyOperator			Operator
  HiLink rubyBeginEnd			Statement
  HiLink rubyAccess			Statement
  HiLink rubyAttribute			Statement
  HiLink rubyEval			Statement
  HiLink rubyPseudoVariable		Constant

  HiLink rubyComment			Comment
  HiLink rubyData			Comment
  HiLink rubyDataDirective		Delimiter
  HiLink rubyDocumentation		Comment
  HiLink rubyEscape			Special
  HiLink rubyInterpolation		Special
  HiLink rubyNoInterpolation		rubyString
  HiLink rubySharpBang			PreProc
  HiLink rubyStringDelimiter		Delimiter
  HiLink rubyString			String
  HiLink rubyTodo			Todo

  delcommand HiLink
endif

let b:current_syntax = "ruby"

" vim: nowrap tabstop=8 ff=unix
