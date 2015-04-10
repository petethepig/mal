require_relative "reader"
require_relative "printer"
require_relative "env"
require_relative "core"

def _read(str)
  read_str str
end

def eval_ast(mal, env)
  case mal.type
  when :symbol
    env.get(mal.val)
  when :list
    _eval(mal, env)
  else
    mal
  end
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
      [Mal.new(:list, args[more_index..-1] || [])]
    else
      args[0..more_index - 1] + [Mal.new(:list, args[more_index..-1] || [])]
    end
  else
    args
  end
end

def _eval(ast, env)
  while true
    if ast.type != :list
      return eval_ast(ast, env)
    else
      list = ast.val
      case list.first.val
      when "def!"
        val = eval_ast(list[2], env)
        env.set(list[1].val, val)
        return val
      when "do"
        list[1..-2].each { |x| eval_ast(x, env) }
        ast = list[-1]
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
          args = more_args(args)
          new_env = Env.new({}, env, arg_names, args)
          _eval(list[2], new_env)
        end
        
        return Mal.new(:function, proc, list[2], old_names, env)
      when "let*"
        new_env = Env.new({}, env)
        list[1].val.each_slice(2) do |list|
          key = list[0]
          val = _eval(list[1], new_env)
          new_env.set(key.val, val)
        end
        ast, env = list[2], new_env
        next
      else
        arr = list.map { |x| eval_ast(x, env) }
        func = arr.shift
        if func.ast
          ast = func.ast
          env = Env.new({}, func.env, more_names(func.params), more_args(func.params, arr))
          next
        else
          return func.val.call(*arr)
        end
      end
    end
  end
end

def _print(mal)
  pr_str(mal, true)
end

def _rep(str)
  begin
    _print(_eval(_read(str), NS))
  rescue => e
    print e.message
  end
end

while (print "user> "; line = gets())
  puts _rep(line)
end
