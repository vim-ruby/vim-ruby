" Ruby
au BufNewFile,BufRead *.rb,*.rbw,*.gem,*.gemspec	setf ruby

" Ruby Makefile
au BufNewFile,BufRead [rR]akefile*			setf ruby

" eRuby
au BufRead,BufNewFile *.rhtml				setf eruby
