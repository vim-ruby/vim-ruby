" Vim completion script
" Language:             Ruby
" Maintainer:           Mark Guzman <segfault@hasno.info>
" Info:                 $Id: rubycomplete.vim,v 1.37 2006/09/19 04:10:32 segy Exp $
" URL:                  http://vim-ruby.rubyforge.org
" Anon CVS:             See above site
" Release Coordinator:  Doug Kearns <dougkearns@gmail.com>
" Maintainer Version:   0.7
" ----------------------------------------------------------------------------
"
" Ruby IRB/Complete author: Keiju ISHITSUKA(keiju@ishitsuka.com)
" ----------------------------------------------------------------------------

" {{{ requirement checks
if !has('ruby')
    s:ErrMsg( "Error: Required vim compiled with +ruby" )
    finish
endif

if version < 700
    s:ErrMsg( "Error: Required vim >= 7.0" )
    finish
endif
" }}} requirement checks

if !exists("g:rubycomplete_rails")
    let g:rubycomplete_rails = 0
endif

if !exists("g:rubycomplete_classes_in_global")
    let g:rubycomplete_classes_in_global = 0
endif

if !exists("g:rubycomplete_buffer_loading")
    let g:rubycomplete_classes_in_global = 0
endif

if !exists("g:rubycomplete_rails_proactive")
    let g:rubycomplete_rails_proactive = 0
endif

" {{{ vim-side support functions
function! s:ErrMsg(msg)
    echohl ErrorMsg
    echo a:msg
    echohl None
endfunction

function! s:GetBufferRubyModule(name)
    let [snum,enum] = s:GetBufferRubyEntity(a:name, "module")
    return snum . '..' . enum
endfunction

function! s:GetBufferRubyClass(name)
    let [snum,enum] = s:GetBufferRubyEntity(a:name, "class")
    return snum . '..' . enum
endfunction

function! s:GetBufferRubySingletonMethods(name)
endfunction

function! s:GetBufferRubyEntity( name, type )
    let stopline = 1
    let crex = '^\s*' . a:type . '\s*' . a:name . '\s*\(<\s*.*\s*\)\?\n*\(\(\s\|#\).*\n*\)*\n*\s*end$'
    let [lnum,lcol] = searchpos( crex, 'nbw')
    if lnum == 0 && lcol == 0
        return [0,0]
    endif

    let [enum,ecol] = searchpos( crex, 'nebw')
    if lnum > enum
        let realdef = getline( lnum )
        let crexb = '^' . realdef . '\n*\(\(\s\|#\).*\n*\)*\n*\s*end$'
        let [enum,ecol] = searchpos( crexb, 'necw' )
    endif
    " we found a the class def
    return [lnum,enum]
endfunction

function! s:IsInClassDef()
    return s:IsPosInClassDef( line('.') )
endfunction

function! s:IsPosInClassDef(pos)
    let [snum,enum] = s:GetBufferRubyEntity( '.*', "class" )
    let ret = 'nil'

    if snum < a:pos && a:pos < enum
        let ret = snum . '..' . enum
    endif

    return ret
endfunction

function! s:GetRubyVarType(v)
    let stopline = 1
    let vtp = ''
    let pos = getpos('.')
    let sstr = '^\s*#\s*@var\s*'.a:v.'\>\s\+[^ \t]\+\s*$'
    let [lnum,lcol] = searchpos(sstr,'nb',stopline)
    if lnum != 0 && lcol != 0
        call setpos('.',pos)
        let str = getline(lnum)
        let vtp = substitute(str,sstr,'\1','')
        return vtp
    endif
    call setpos('.',pos)
    let ctors = '\(now\|new\|open\|get_instance'
    if exists('g:rubycomplete_rails') && g:rubycomplete_rails == 1 && s:rubycomplete_rails_loaded == 1
        let ctors = ctors.'\|find\|create'
    else
    endif
    let ctors = ctors.'\)'

    let fstr = '=\s*\([^ \t]\+.' . ctors .'\>\|[\[{"''/]\|%r{\|[A-Za-z0-9@:\-()\.]\+...\?\)'
    let sstr = ''.a:v.'\>\s*[+\-*/]*'.fstr
    let [lnum,lcol] = searchpos(sstr,'nb',stopline)
    if lnum != 0 && lcol != 0
        let str = matchstr(getline(lnum),fstr,lcol)
        let str = substitute(str,'^=\s*','','')
        call setpos('.',pos)
        if str == '"' || str == ''''
            return 'String'
        elseif str == '['
            return 'Array'
        elseif str == '{'
            return 'Hash'
        elseif str == '/' || str == '%r{'
            return 'Regexp'
        elseif strlen(str) >= 4 && stridx(str,'..') != -1
            return 'Range'
        elseif strlen(str) > 4
            let l = stridx(str,'.')
            return str[0:l-1]
        end
        return ''
    endif
    call setpos('.',pos)
    return ''
endfunction

"}}} vim-side support functions

function! rubycomplete#Complete(findstart, base)
     "findstart = 1 when we need to get the text length
    if a:findstart
        let line = getline('.')
        let idx = col('.')
        while idx > 0
            let idx -= 1
            let c = line[idx-1]
            if c =~ '\w'
                continue
            elseif ! c =~ '\.'
                idx = -1
                break
            else
                break
            endif
        endwhile

        return idx
    "findstart = 0 when we need to return the list of completions
    else
        let g:rubycomplete_completions = []
        execute "ruby VimRubyCompletion.get_completions('" . a:base . "')"
        return g:rubycomplete_completions
    endif
endfunction


function! s:DefRuby()
ruby << RUBYEOF
# {{{ ruby completion

begin
    require 'rubygems'
rescue Exception
    #ignore?
end
class VimRubyCompletion
  # {{{ constants
  @@debug = false
  @@ReservedWords = [
        "BEGIN", "END",
        "alias", "and",
        "begin", "break",
        "case", "class",
        "def", "defined", "do",
        "else", "elsif", "end", "ensure",
        "false", "for",
        "if", "in",
        "module",
        "next", "nil", "not",
        "or",
        "redo", "rescue", "retry", "return",
        "self", "super",
        "then", "true",
        "undef", "unless", "until",
        "when", "while",
        "yield",
      ]

  @@Operators = [ "%", "&", "*", "**", "+",  "-",  "/",
        "<", "<<", "<=", "<=>", "==", "===", "=~", ">", ">=", ">>",
        "[]", "[]=", "^", ]
  #}}} constants


  def load_requires
    buf = VIM::Buffer.current
    enum = buf.line_number
    nums = Range.new( 1, enum )
    nums.each do |x|
      ln = buf[x]
      begin
        eval( "require %s" % $1 ) if /.*require\s*(.*)$/.match( ln )
      rescue Exception
        #ignore?
      end
    end
  end

  def load_buffer_class(name)
    classdef = get_buffer_entity(name, 's:GetBufferRubyClass("%s")')
    return if classdef == nil

    pare = /^\s*class\s*(.*)\s*<\s*(.*)\s*\n/.match( classdef )
    load_buffer_class( $2 ) if pare != nil

    mixre = /.*\n\s*include\s*(.*)\s*\n/.match( classdef )
    load_buffer_module( $2 ) if mixre != nil

    begin
      eval classdef
    rescue Exception
      VIM::evaluate( "s:ErrMsg( 'Problem loading class \"%s\", was it already completed?' )" % name )
    end
  end

  def load_buffer_module(name)
    classdef = get_buffer_entity(name, 's:GetBufferRubyModule("%s")')
    return if classdef == nil

    begin
      eval classdef
    rescue Exception
      VIM::evaluate( "s:ErrMsg( 'Problem loading module \"%s\", was it already completed?' )" % name )
    end
  end

  def get_buffer_entity(name, vimfun)
    loading_allowed = VIM::evaluate("exists('g:rubycomplete_buffer_loading') && g:rubycomplete_buffer_loading")
    return nil if loading_allowed != '1'
    return nil if /(\"|\')+/.match( name )
    buf = VIM::Buffer.current
    nums = eval( VIM::evaluate( vimfun % name ) )
    return nil if nums == nil
    return nil if nums.min == nums.max && nums.min == 0

    cur_line = VIM::Buffer.current.line_number
    classdef = ""
    nums.each do |x|
      if x != cur_line
        ln = buf[x]
        if /^\s*(module|class|def|include)\s+/.match(ln)
            classdef += "%s\n" % ln
            classdef += "end\n" if /def\s+/.match(ln)
            dprint ln
        end
      end
    end
    classdef += "end\n" if classdef.length > 1

    return classdef
  end

  def get_var_type( receiver )
    if /(\"|\')+/.match( receiver )
      "String"
    else
      VIM::evaluate("s:GetRubyVarType('%s')" % receiver)
    end
  end

  def dprint( txt )
    print txt if @@debug
  end

  def get_buffer_entity_list( type )
    # this will be a little expensive.
    loading_allowed = VIM::evaluate("exists('g:rubycomplete_buffer_loading') && g:rubycomplete_buffer_loading")
    allow_aggressive_load = VIM::evaluate("exists('g:rubycomplete_classes_in_global') && g:rubycomplete_classes_in_global")
    return [] if allow_aggressive_load != '1' || loading_allowed != '1'

    buf = VIM::Buffer.current
    eob = buf.length
    ret = []
    rg = 1..eob
    re = eval( "/^\s*%s\s*([A-Za-z0-9_-]*)(\s*<\s*([A-Za-z0-9_:-]*))?\s*/" % type )

    rg.each do |x|
      if re.match( buf[x] )
        next if type == "def" && eval( VIM::evaluate("s:IsPosInClassDef(%s)" % x) ) != nil
        ret.push $1
      end
    end

    return ret
  end

  def get_buffer_modules
    return get_buffer_entity_list( "modules" )
  end

  def get_buffer_methods
    return get_buffer_entity_list( "def" )
  end

  def get_buffer_classes
    return get_buffer_entity_list( "class" )
  end


  def load_rails
    allow_rails = VIM::evaluate("exists('g:rubycomplete_rails') && g:rubycomplete_rails")
    return if allow_rails != '1'

    buf_path = VIM::evaluate('expand("%:p")')
    file_name = VIM::evaluate('expand("%:t")')
    vim_dir = VIM::evaluate('getcwd()')
    file_dir = buf_path.gsub( file_name, '' )
    file_dir.gsub!( /\\/, "/" )
    vim_dir.gsub!( /\\/, "/" )
    vim_dir << "/"
    dirs = [ vim_dir, file_dir ]
    sdirs = [ "", "./", "../", "../../", "../../../", "../../../../" ]
    rails_base = nil

    dirs.each do |dir|
      sdirs.each do |sub|
        trail = "%s%s" % [ dir, sub ]
        tcfg = "%sconfig" % trail

        if File.exists?( tcfg )
          rails_base = trail
          break
        end
      end
      break if rails_base
    end

    return if rails_base == nil
    $:.push rails_base unless $:.index( rails_base )

    rails_config = rails_base + "config/"
    rails_lib = rails_base + "lib/"
    $:.push rails_config unless $:.index( rails_config )
    $:.push rails_lib unless $:.index( rails_lib )

    bootfile = rails_config + "boot.rb"
    envfile = rails_config + "environment.rb"
    if File.exists?( bootfile ) && File.exists?( envfile )
      begin
        require bootfile
        require envfile
        begin
          require 'console_app'
          require 'console_with_helpers'
        rescue Exception
          dprint "Rails 1.1+ Error %s" % $!
          # assume 1.0
        end
        eval( "Rails::Initializer.run" )
        VIM::command('let s:rubycomplete_rails_loaded = 1')
      rescue Exception
        dprint "Rails Error %s" % $!
        VIM::evaluate( "s:ErrMsg('Error loading rails environment')" )
      end
    end
  end

  def get_rails_helpers
    allow_rails = VIM::evaluate("exists('g:rubycomplete_rails') && g:rubycomplete_rails")
    rails_loaded = VIM::evaluate('s:rubycomplete_rails_loaded')
    return [] if allow_rails != '1' || rails_loaded != '1'

    buf_path = VIM::evaluate('expand("%:p")')
    buf_path.gsub!( /\\/, "/" )
    path_elm = buf_path.split( "/" )
    i = path_elm.index( "app" )

    return [] unless i
    i += 1
    type = path_elm[i]
    type.downcase!

    ret = []
    case type
      when "views"
        ret += ActionView::Base.instance_methods
        ret += ActionView::Base.methods
      when "controllers"
        ret += ActionController::Base.instance_methods
        ret += ActionController::Base.methods
      when "models"
        ret += ActiveRecord::Base.instance_methods
        ret += ActiveRecord::Base.methods
    end

    return ret
  end

  def add_rails_columns( cls )
    allow_rails = VIM::evaluate("exists('g:rubycomplete_rails') && g:rubycomplete_rails")
    rails_loaded = VIM::evaluate('s:rubycomplete_rails_loaded')
    return [] if allow_rails != '1' || rails_loaded != '1'
    begin
        eval( "#{cls}.establish_connection" )
        return [] unless eval( "#{cls}.ancestors.include?(ActiveRecord::Base).to_s" )
        col = eval( "#{cls}.column_names" )
        return col if col
    rescue
        return []
    end
    return []
  end

  def clean_sel(sel, msg)
    sel.delete_if { |x| x == nil }
    sel.uniq!
    sel.grep(/^#{Regexp.quote(msg)}/) if msg != nil
  end

  def get_rails_view_methods
    allow_rails = VIM::evaluate("exists('g:rubycomplete_rails') && g:rubycomplete_rails")
    rails_loaded = VIM::evaluate('s:rubycomplete_rails_loaded')
    return [] if allow_rails != '1' || rails_loaded != '1'

    buf_path = VIM::evaluate('expand("%:p")')
    buf_path.gsub!( /\\/, "/" )
    pelm = buf_path.split( "/" )
    idx = pelm.index( "views" )

    return [] unless idx
    idx += 1

    clspl = pelm[idx].camelize.pluralize
    cls = clspl.singularize

    ret = []
    ret += eval( "#{cls}.instance_methods" )
    ret += eval( "#{clspl}Helper.instance_methods" )
    return ret
  end

  def self.get_completions(base)
    b = VimRubyCompletion.new
    b.get_completions base
  end

  def get_completions(base)
    loading_allowed = VIM::evaluate("exists('g:rubycomplete_buffer_loading') && g:rubycomplete_buffer_loading")
    if loading_allowed == '1'
      load_requires
      load_rails
    end

    input = VIM::Buffer.current.line
    cpos = VIM::Window.current.cursor[1] - 1
    input = input[0..cpos]
    input += base
    input.sub!(/.*[ \t\n\"\\'`><=;|&{(]/, '') # Readline.basic_word_break_characters
    input.sub!(/self\./, '')

    message = nil
    receiver = nil
    methods = []
    variables = []
    classes = []

    case input
      when /^(\/[^\/]*\/)\.([^.]*)$/ # Regexp
        receiver = $1
        message = Regexp.quote($2)
        methods = Regexp.instance_methods(true)

      when /^([^\]]*\])\.([^.]*)$/ # Array
        receiver = $1
        message = Regexp.quote($2)
        methods = Array.instance_methods(true)

      when /^([^\}]*\})\.([^.]*)$/ # Proc or Hash
        receiver = $1
        message = Regexp.quote($2)
        methods = Proc.instance_methods(true) | Hash.instance_methods(true)

      when /^(:[^:.]*)$/ # Symbol
        dprint "symbol"
        if Symbol.respond_to?(:all_symbols)
          receiver = $1
          message = $1.sub( /:/, '' )
          methods = Symbol.all_symbols.collect{|s| s.id2name}
          methods.delete_if { |c| c.match( /'/ ) }
        end

      when /^::([A-Z][^:\.\(]*)$/ # Absolute Constant or class methods
        dprint "const or cls"
        receiver = $1
        methods = Object.constants
        methods.grep(/^#{receiver}/).collect{|e| "::" + e}

      when /^(((::)?[A-Z][^:.\(]*)+)::?([^:.]*)$/ # Constant or class methods
        dprint "const or cls 2"
        receiver = $1
        message = Regexp.quote($4)
        begin
          methods = eval("#{receiver}.constants | #{receiver}.methods")
        rescue Exception
          methods = []
        end
        methods.grep(/^#{message}/).collect{|e| receiver + "::" + e}

      when /^(:[^:.]+)\.([^.]*)$/ # Symbol
        receiver = $1
        message = Regexp.quote($2)
        methods = Symbol.instance_methods(true)

      when /^([0-9_]+(\.[0-9_]+)?(e[0-9]+)?)\.([^.]*)$/ # Numeric
        receiver = $1
        message = Regexp.quote($4)
        begin
          methods = eval(receiver).methods
        rescue Exception
          methods = []
        end

      when /^(\$[^.]*)$/ #global
        methods = global_variables.grep(Regexp.new(Regexp.quote($1)))

      when /^((\.?[^.]+)+)\.([^.]*)$/ # variable
        receiver = $1
        message = Regexp.quote($3)
        load_buffer_class( receiver )

        cv = eval("self.class.constants")
        vartype = get_var_type( receiver )
        dprint "vartype: %s" % vartype
        if vartype != ''
          load_buffer_class( vartype )

          begin
            methods = eval("#{vartype}.instance_methods")
            variables = eval("#{vartype}.instance_variables")
          rescue Exception
            dprint "load_buffer_class err: %s" % $!
          end
        elsif (cv).include?(receiver)
          # foo.func and foo is local var.
          methods = eval("#{receiver}.methods")
          vartype = receiver
        elsif /^[A-Z]/ =~ receiver and /\./ !~ receiver
          vartype = receiver
          # Foo::Bar.func
          begin
            methods = eval("#{receiver}.methods")
          rescue Exception
          end
        else
          # func1.func2
          ObjectSpace.each_object(Module){|m|
            next if m.name != "IRB::Context" and
              /^(IRB|SLex|RubyLex|RubyToken)/ =~ m.name
            methods.concat m.instance_methods(false)
          }
        end
        variables += add_rails_columns( "#{vartype}" ) if vartype && vartype.length > 0

      when /^\(?\s*[A-Za-z0-9:^@.%\/+*\(\)]+\.\.\.?[A-Za-z0-9:^@.%\/+*\(\)]+\s*\)?\.([^.]*)/
        message = $1
        methods = Range.instance_methods(true)

      when /^\.([^.]*)$/ # unknown(maybe String)
        message = Regexp.quote($1)
        methods = String.instance_methods(true)

    else
      inclass = eval( VIM::evaluate("s:IsInClassDef()") )

      if inclass != nil
        classdef = "%s\n" % VIM::Buffer.current[ inclass.min ]
        found = /^\s*class\s*([A-Za-z0-9_-]*)(\s*<\s*([A-Za-z0-9_:-]*))?\s*\n$/.match( classdef )

        if found != nil
          receiver = $1
          message = input
          load_buffer_class( receiver )
          begin
            methods = eval( "#{receiver}.instance_methods" )
            methods += get_rails_helpers
            variables += add_rails_columns( "#{receiver}" )
          rescue Exception
            found = nil
          end
        end
      end

      if inclass == nil || found == nil
        methods = get_buffer_methods
        methods += get_rails_helpers
        methods += get_rails_view_methods
        classes = eval("self.class.constants")
        classes += get_buffer_classes
        classes += get_buffer_modules
        message = receiver = input
      end

      methods += Kernel.public_methods
    end

    methods = clean_sel( methods, message )
    methods = (methods-Object.instance_methods)
    variables = clean_sel( variables, message )
    classes = clean_sel( classes, message )
    valid = []
    valid += methods.collect { |m| { :name => m, :type => 'f' } }
    valid += variables.collect { |v| { :name => v, :type => 'v' } }
    valid += classes.collect { |c| { :name => c, :type => 't' } }
    valid.sort! { |x,y| x[:name] <=> y[:name] }

    outp = ""

    rg = 0..valid.length
    rg.step(150) do |x|
      stpos = 0+x
      enpos = 150+x
      valid[stpos..enpos].each { |c| outp += "{'word':'%s','item':'%s','kind':'%s'}," % [ c[:name], c[:name], c[:type] ] }
      outp.sub!(/,$/, '')

      VIM::command("call extend(g:rubycomplete_completions, [%s])" % outp)
      outp = ""
    end
  end

end # VimRubyCompletion
# }}} ruby completion
RUBYEOF
endfunction

let s:rubycomplete_rails_loaded = 0

call s:DefRuby()


" vim:tw=78:sw=4:ts=8:et:fdm=marker:ft=vim:norl:
