" This is an adapted version of :GoDoc from vim-go
" https://github.com/fatih/vim-go/blob/master/autoload/go/doc.vim

let s:ri_buf_nr = -1

function! ri#doc(newposition, position, keyword) abort
  call ri#buf(a:newposition, a:position, system('ri -T -f markdown ' . a:keyword))
endfunc

function! ri#buf(newposition, position, content) abort
  " reuse existing buffer window if it exists otherwise create a new one
  let is_visible = bufexists(s:ri_buf_nr) && bufwinnr(s:ri_buf_nr) != -1
  if !bufexists(s:ri_buf_nr)
    execute a:newposition
    sil file `="[Ri]"`
    let s:ri_buf_nr = bufnr('%')
  elseif bufwinnr(s:ri_buf_nr) == -1
    execute a:position
    execute s:ri_buf_nr . 'buffer'
  elseif bufwinnr(s:ri_buf_nr) != bufwinnr('%')
    execute bufwinnr(s:ri_buf_nr) . 'wincmd w'
  endif


  " if window was not visible then resize it
  if !is_visible
    if a:position ==# 'split'
      " cap window height to 20, but resize it for smaller contents
      let max_height = 20
      let content_height = len(split(a:content, "\n"))
      if content_height > max_height
        exe 'resize ' . max_height
      else
        exe 'resize ' . content_height
      endif
    else
      " set a sane maximum width for vertical splits. In this case the minimum
      " that fits the godoc for package http without extra linebreaks and line
      " numbers on
      exe 'vertical resize 84'
    endif
  endif

  setlocal filetype=rubyri
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nocursorline
  setlocal nocursorcolumn
  setlocal iskeyword+=:
  setlocal iskeyword-=-

  setlocal modifiable
  %delete _
  call append(0, split(a:content, "\n"))
  sil $delete _
  setlocal nomodifiable
  sil normal! gg

  " close easily with <esc> or enter
  noremap <buffer> <silent> <CR> :<C-U>close<CR>
  noremap <buffer> <silent> <Esc> :<C-U>close<CR>
endfunc
