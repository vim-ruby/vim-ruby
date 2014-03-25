function! s:setf(filetype) abort
  if &filetype !=# a:filetype
    let &filetype = a:filetype
  endif
endfunction

" Ruby
au BufNewFile,BufRead *.rb,*.rbw,*.gemspec	call s:setf('ruby')

" Ruby on Rails
au BufNewFile,BufRead *.builder,*.rxml,*.rjs,*.ruby call s:setf('ruby')

" Rakefile
au BufNewFile,BufRead [rR]akefile,*.rake	call s:setf('ruby')

" Rantfile
au BufNewFile,BufRead [rR]antfile,*.rant	call s:setf('ruby')

" IRB config
au BufNewFile,BufRead .irbrc,irbrc		call s:setf('ruby')

" Pry config
au BufNewFile,BufRead .pryrc			call s:setf('ruby')

" Rackup
au BufNewFile,BufRead *.ru			call s:setf('ruby')

" Capistrano
au BufNewFile,BufRead Capfile			call s:setf('ruby')

" Bundler
au BufNewFile,BufRead Gemfile			call s:setf('ruby')

" Guard
au BufNewFile,BufRead Guardfile,.Guardfile	call s:setf('ruby')

" Chef
au BufNewFile,BufRead Cheffile			call s:setf('ruby')
au BufNewFile,BufRead Berksfile			call s:setf('ruby')

" Vagrant
au BufNewFile,BufRead [vV]agrantfile		call s:setf('ruby')

" Autotest
au BufNewFile,BufRead .autotest			call s:setf('ruby')

" eRuby
au BufNewFile,BufRead *.erb,*.rhtml		call s:setf('eruby')

" Thor
au BufNewFile,BufRead [tT]horfile,*.thor	call s:setf('ruby')

" Rabl
au BufNewFile,BufRead *.rabl			call s:setf('ruby')

" Jbuilder
au BufNewFile,BufRead *.jbuilder		call s:setf('ruby')

" Puppet librarian
au BufNewFile,BufRead Puppetfile		call s:setf('ruby')
"
" Buildr Buildfile
au BufNewFile,BufRead [Bb]uildfile		call s:setf('ruby')

" Appraisal
au BufNewFile,BufRead Appraisals		call s:setf('ruby')

" CocoaPods
au BufNewFile,BufRead Podfile,*.podspec		call s:setf('ruby')

" vim: nowrap sw=2 sts=2 ts=8 noet:
