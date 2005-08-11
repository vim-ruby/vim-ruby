" Ruby
au BufNewFile,BufRead *.rb,*.rbw,*.gem,*.gemspec	setf ruby

" Rakefile
au BufNewFile,BufRead [rR]akefile*			setf ruby

" eRuby
au BufNewFile,BufRead *.rhtml				setf eruby
