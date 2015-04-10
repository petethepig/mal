require_relative "reader"
require_relative "printer"
require_relative "env"

Repl_env = Env.new({
  '+' => Proc.new { |a, b| Mal.new(:number, a.val + b.val) },
  '-' => Proc.new { |a, b| Mal.new(:number, a.val - b.val) },
  '*' => Proc.new { |a, b| Mal.new(:number, a.val * b.val) },
  '/' => Proc.new { |a, b| Mal.new(:number, a.val / b.val) },
})

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
    proc.call(*arr)
  else
    eval_ast(mal, env)
  end
end

def _print(mal)
  pr_str(mal, true)
end

def _rep(str)
  begin
    _print(_eval(_read(str), Repl_env))
  rescue => e
    print e.message
  end
end

while (print "user> "; line = gets())
  puts _rep(line)
end

