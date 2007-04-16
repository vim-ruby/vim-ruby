" Ruby
au BufNewFile,BufRead *.rb,*.rbw,*.rjs,*.rxml,*.gem,*.gemspec	set filetype=ruby

" Rakefile
au BufNewFile,BufRead [rR]akefile*				set filetype=ruby

" Rantfile
au BufNewFile,BufRead [rR]antfile,*.rant			set filetype=ruby

" eRuby
au BufNewFile,BufRead *.erb,*.rhtml				set filetype=eruby
