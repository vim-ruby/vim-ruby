# controlled by g:ruby_hanging_indent

@foo ||= begin
           bar
           baz
         end

@foo = case @bar
       when :one
         1
       when :two
         2
       end

@foo = if @bar.nil?
         :one
       else
         :two
       end

foo = while foo
        bar
      end
