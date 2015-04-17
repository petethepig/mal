#!/usr/bin/env ruby

require_relative "reader"
require_relative "printer"
require_relative "env"
require_relative "core"
require "readline"

def _read(str)
  if str =~ /\Aexit/
    exit 0
  end
  read_str str
end

def eval_ast(ast, env)
  case ast
  when Symbol
    env.get(ast)
  when MalList
    _eval(ast, env)
  else
    ast
  end
end

def is_macro_call(ast, env)
  if ast.is_a?(MalList)
    if (first = ast.first) && first.is_a?(Symbol)
      if env.find(first) && (func = env.get(first)) && func.is_a?(MalFunction) && func.is_macro
        return true
      end
    end
  end
  false
end

def macroexpand(ast, env)
  while is_macro_call(ast, env)
    func = env.get(ast.first)
    ast = func.call(*ast.drop(1))
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
      MalList.new([args])
    else
      MalList.new(args[0..more_index - 1] + [args.drop(more_index)])
    end
  else
    args
  end
end

def is_pair(ast)
  ast.is_a?(MalList) && ast.count > 0
end

def quasiquote(ast)
  if !is_pair(ast)
    MalList.new([:quote, ast])
  elsif ast[0].type == :symbol && ast[0] == :unquote
    ast[1]
  elsif is_pair(ast[0]) && ast[0][0].type == :symbol && ast[0][0] == :'splice-unquote'
    MalList.new([:concat, ast[0][1], quasiquote(MalList.new(ast.drop(1)))])
  else
    MalList.new([:cons, quasiquote(ast[0]), quasiquote(MalList.new(ast.drop(1)))])
  end
end

def _eval(ast, env)
  while true
    if !ast.is_a?(MalList)
      return eval_ast(ast, env)
    else
      # macro stuff
      ast = macroexpand(ast, env)
      return ast unless ast.is_a?(Array)
      #

      list = ast
      case list.first
      when :"def!"
        val = eval_ast(list[2], env)
        env.set(list[1], val)
        return val
      when :"defmacro!"
        val = eval_ast(list[2], env)
        val.is_macro = true
        env.set(list[1], val)
        return val
      when :"do"
        list[1..-2].each { |x| eval_ast(x, env) }
        ast = list[-1]
        next
      when :"try*"
        begin
          return eval_ast(list[1], env)
        rescue => e
          if list[2] && list[2].type == :list && list[2][0] && list[2][0].type == :symbol && list[2][0] == "catch*"
            name = list[2][1]
            exp = 
              if e.is_a? MalException
                Mal.new(:exception, e)
              else
                Mal.new(:exception, Mal.new(:string, e.message))
              end
            ast = list[2][2]
            env = Env.new({}, env, [name], [exp])
            next
          else
            raise
          end
        end
      when :"quote"
        return list[1]
      when :"quasiquote"
        ast = quasiquote(list[1])
        next
      when :"if"
        cond = eval_ast(list[1], env)
        if cond != nil && cond != false
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
      when :"fn*"
        old_names = arg_names = list[1].map { |x| x }
        arg_names = more_names(arg_names)
        func = MalFunction.new(list[2], old_names, env) do |*args|
          args = more_args(old_names, args)
          new_env = Env.new({}, env, arg_names, args)
          _eval(list[2], new_env)
        end
        return func
      when :"let*"
        new_env = Env.new({}, env)
        list[1].each_slice(2) do |x|
          key = x[0]
          val = _eval(x[1], new_env)
          new_env.set(key, val)
        end
        ast, env = list[2], new_env
        next
      when :"macroexpand"
        return macroexpand(list[1], env)
      else
        arr = list.map { |x| eval_ast(x, env) }
        func = arr[0]
        raise 'call on non function' unless func && func.is_a?(MalFunction)
        if func.ast
          ast = func.ast
          env = Env.new({}, func.env, more_names(func.params), more_args(func.params, arr.drop(1)))
          next
        else
          return func.call(*arr.drop(1))
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
  rescue EmptyError => e
    nil
  end
end

def _repl(str)
  begin
    a = _rep(str)
    puts(a) unless a.nil?
  rescue => e
    puts "Error: #{e.message}"
    puts "  " + e.backtrace.join("\n  ")
  end
end

# puts ARGV
NS.set(:'eval', func { |ast| _eval(ast, NS) })
NS.set(:'*ARGV*', MalList.new(ARGV))

_rep "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))"
_rep "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"
_rep "(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))"
_rep "(def! *host-language* \"dima\")"
# _rep "(load-file \"core.mal\")"
_rep "(map load-file *ARGV*)"

while line = Readline.readline("user> ", true)
  _repl(line)
end
