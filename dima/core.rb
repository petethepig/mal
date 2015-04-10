require_relative 'types'
require_relative 'printer'
require_relative 'env'

def func(&block)
  Mal.new(:function, Proc.new(&block))
end

def bool(a)
  if a
    Mal.new(:true, true)
  else
    Mal.new(:false, false)
  end
end

def equality(a, b)
  return false if a.type != b.type
  if a.type == :list
    return false if a.val.count != b.val.count
    a.val.each_index do |i|
      if !equality(a.val[i], b.val[i])
        return false
      end
      true
    end
  else
    a.val == b.val
  end
end

NS = Env.new({
  '=' => func { |a, b| bool(equality(a, b)) },
  '>' => func { |a, b| bool(a.val > b.val) },
  '>=' => func { |a, b| bool(a.val >= b.val) },
  '<' => func { |a, b| bool(a.val < b.val) },
  '<=' => func { |a, b| bool(a.val <= b.val) },
  '+' => func { |a, b| Mal.new(:number, a.val + b.val) },
  '-' => func { |a, b| Mal.new(:number, a.val - b.val) },
  '*' => func { |a, b| Mal.new(:number, a.val * b.val) },
  '/' => func { |a, b| Mal.new(:number, a.val / b.val) },
  'list' => func { |*args| Mal.new(:list, args) },
  'list?' => func { |obj| bool(obj.type == :list) },
  'empty?' => func { |list| bool(list.val.count == 0) },
  'count' => func { |list| Mal.new(:number, list.type == :list ? list.val.count : 0) },
  'not' => func { |x| bool(x.type == :nil || x.type == :false) },
  'pr-str' => func { |*args| Mal.new(:string, args.map { |x| pr_str(x, true) }.join(' ')) },
  'str' => func { |*args| Mal.new(:string, args.map { |x| pr_str(x, false) }.join('')) },
  'prn' => func { |*args| puts args.map { |x| pr_str(x, true) }.join(' '); Mal.new(:nil, nil) },
  'println' => func { |*args| puts args.map { |x| pr_str(x, false) }.join(' '); Mal.new(:nil, nil) },
})