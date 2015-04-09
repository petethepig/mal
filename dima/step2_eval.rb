require_relative "reader"
require_relative "printer"

def _read(str)
  read_str str
end

def eval_ast(mal, env)
  case mal.type
  when :symbol
    if env.has_key?(mal.val)
      env[mal.val]
    else
      fail "'#{mal.val}' not found"
    end
  when :list
    _eval(mal, env)
  else
    mal
  end
end

def _eval(mal, env)
  case mal.type
  when :list
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
  repl_env = {
    '+' => Proc.new { |a, b| Mal.new(:number, a.val + b.val) },
    '-' => Proc.new { |a, b| Mal.new(:number, a.val - b.val) },
    '*' => Proc.new { |a, b| Mal.new(:number, a.val * b.val) },
    '/' => Proc.new { |a, b| Mal.new(:number, a.val / b.val) },
  }
  begin
    _print(_eval(_read(str), repl_env))
  rescue => e
    print e.message
  end
end

while (print "user> "; line = gets())
  puts _rep(line)
end

