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

def _eval(mal, env)
  case mal.type
  when :list
    first = mal.val.first
    if first.type == :symbol
      case first.val
      when "def!"
        val = eval_ast(mal.val[2], env)
        env.set(mal.val[1].val, val)
        return val
      when "do"
        return mal.val[1..-1].map { |x| eval_ast(x, env) }.last
      when "if"
        cond = eval_ast(mal.val[1], env)
        ret = 
          if cond.val != nil && cond.val != false
            eval_ast(mal.val[2], env)
          else
            if mal.val[3]
              eval_ast(mal.val[3], env)
            else
              Mal.new(:nil, nil)
            end
          end
        return ret
      when "fn*"
        arg_names = mal.val[1].val.map { |x| x.val }
        if more_index = arg_names.index('&')
          if more_index == 0
            arg_names = [arg_names[more_index + 1]]
          else
            arg_names = arg_names[0..more_index - 1] + [arg_names[more_index + 1]]
          end
        end
        proc = Proc.new do |*args|
          if more_index
            if more_index == 0
              args = [Mal.new(:list, args[more_index..-1] || [])]
            else
              args = args[0..more_index - 1] + [Mal.new(:list, args[more_index..-1] || [])]
            end
          end
          new_env = Env.new({}, env, arg_names, args)
          _eval(mal.val[2], new_env)
        end
        
        return Mal.new(:function, proc)
      when "let*"
        new_env = Env.new({}, env)
        mal.val[1].val.each_slice(2) do |list|
          key = list[0]
          val = _eval(list[1], new_env)
          new_env.set(key.val, val)
        end
        return _eval(mal.val[2], new_env)
      end
    end
    arr = mal.val.map { |x| eval_ast(x, env) }
    proc = arr.shift
    proc.val.call(*arr)
  else
    eval_ast(mal, env)
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

