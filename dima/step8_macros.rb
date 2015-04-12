require_relative "../ruby/mal_readline"
require_relative "reader"
require_relative "printer"
require_relative "env"
require_relative "core"

def _read(str)
  if str =~ /\Aexit/
    exit 0
  end
  read_str str
end

def eval_ast(ast, env)
  case ast.type
  when :symbol
    env.get(ast.val)
  when :list
    _eval(ast, env)
  else
    ast
  end
end

def is_macro_call(ast, env)
  if ast.type == :list
    if (first = ast.val.first) && first.type == :symbol 
      if env.find(first.val) && (func = env.get(first.val)) && func.type == :function && func.is_macro
        return true
      end
    end
  end
  false
end

def macroexpand(ast, env)
  while is_macro_call(ast, env)
    func = env.get(ast.val.first.val)
    ast = func.val.call(*ast.val.drop(1))
  end
  ast
end

def more_names(names)
  if more_index = names.index('&')
    if more_index == 0
      [names[more_index + 1]]
    else
      names[0..more_index - 1] + [names[more_index + 1]]
    end
  else
    names
  end
end

def more_args(names, args)
  if more_index = names.index('&')
    if more_index == 0
      [Mal.new(:list, args)]
    else
      args[0..more_index - 1] + [Mal.new(:list, args.drop(more_index))]
    end
  else
    args
  end
end

def is_pair(ast)
  ast.type == :list && ast.val.count > 0
end

def quasiquote(ast)
  if !is_pair(ast)
    Mal.new(:list, [Mal.new(:symbol, 'quote'), ast])
  elsif ast.val[0].type == :symbol && ast.val[0].val == 'unquote'
    ast.val[1]
  elsif is_pair(ast.val[0]) && ast.val[0].val[0].type == :symbol && ast.val[0].val[0].val == 'splice-unquote'
    Mal.new(:list, [Mal.new(:symbol, 'concat'), ast.val[0].val[1], quasiquote(Mal.new(:list, ast.val.drop(1)))])
  else
    Mal.new(:list, [Mal.new(:symbol, 'cons'), quasiquote(ast.val[0]), quasiquote(Mal.new(:list, ast.val.drop(1)))])
  end
end

def _eval(ast, env)
  while true
    if ast.type != :list
      return eval_ast(ast, env)
    else
      # macro stuff
      ast = macroexpand(ast, env)
      return ast unless ast.type == :list
      #

      list = ast.val
      case list.first.val
      when "def!"
        val = eval_ast(list[2], env)
        env.set(list[1].val, val)
        return val
      when "defmacro!"
        val = eval_ast(list[2], env)
        val.is_macro = true
        env.set(list[1].val, val)
        return val
      when "do"
        list[1..-2].each { |x| eval_ast(x, env) }
        ast = list[-1]
        next
      when "quote"
        return list[1]
      when "quasiquote"
        ast = quasiquote(list[1])
        next
      when "if"
        cond = eval_ast(list[1], env)
        if cond.val != nil && cond.val != false
          ast = list[2]
          next
        else
          if list[3]
            ast = list[3]
            next
          else
            return Mal.new(:nil, nil)
          end
        end
      when "fn*"
        old_names = arg_names = list[1].val.map { |x| x.val }
        arg_names = more_names(arg_names)
        proc = Proc.new do |*args|
          args = more_args(old_names, args)
          # puts "args: #{arg_names.inspect} #{args.inspect}"
          new_env = Env.new({}, env, arg_names, args)
          _eval(list[2], new_env)
        end
        
        return MalFunction.new(proc, list[2], old_names, env)
      when "let*"
        new_env = Env.new({}, env)
        list[1].val.each_slice(2) do |x|
          key = x[0]
          val = _eval(x[1], new_env)
          new_env.set(key.val, val)
        end
        ast, env = list[2], new_env
        next
      when "macroexpand"
        return macroexpand(list[1], env)
      else
        arr = list.map { |x| eval_ast(x, env) }
        # func = arr.shift
        func = arr[0]
        raise 'call on non function' unless func && func.type == :function
        # if func.ast
        #   ast = func.ast
        #   env = Env.new({}, func.env, more_names(func.params), more_args(func.params, arr.drop(1)))
        #   next
        # else
          return func.val.call(*arr.drop(1))
        # end
      end
    end
  end
end

def _print(mal)
  pr_str(mal, true)
end

def _rep(str)
  _print(_eval(_read(str), NS))
end

NS.set('eval', func { |ast| _eval(ast, NS) })

_rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))")
_rep "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"
_rep "(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))"
# _rep "(load-file \"core.mal\")"

while (print "user> "; line = gets())
  begin
    puts _rep(line)  
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
