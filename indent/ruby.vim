" Vim indent file
" Language:		Ruby
" Maintainer:		Andrew Radev <andrey.radev@gmail.com>
" Previous Maintainer:	Nikolai Weibull <now at bitwi.se>
" URL:			https://github.com/vim-ruby/vim-ruby
" Release Coordinator:	Doug Kearns <dougkearns@gmail.com>

" 0. Initialization {{{1
" =================

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

if !exists('g:ruby_indent_access_modifier_style')
  " Possible values: "normal", "indent", "outdent"
  let g:ruby_indent_access_modifier_style = 'normal'
endif

if !exists('g:ruby_indent_assignment_style')
  " Possible values: "variable", "hanging"
  let g:ruby_indent_assignment_style = 'hanging'
endif

if !exists('g:ruby_indent_block_style')
  " Possible values: "expression", "do"
  let g:ruby_indent_block_style = 'do'
endif

if !exists('g:ruby_indent_hanging_elements')
  " Non-zero means hanging indents are enabled, zero means disabled
  let g:ruby_indent_hanging_elements = 1
endif

setlocal nosmartindent

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetRubyIndent(v:lnum)
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,:,.
setlocal indentkeys+==end,=else,=elsif,=when,=in,=ensure,=rescue,==begin,==end
setlocal indentkeys+==private,=protected,=public

" Only define the function once.
if exists("*GetRubyIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

function! GetRubyIndent(...) abort
  return ruby_vim9#GetRubyIndent(a:0 ? a:1 : v:lnum)
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:set sw=2 sts=2 ts=8 et:
