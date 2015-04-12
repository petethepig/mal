require_relative 'types'
require_relative 'reader'
require_relative 'printer'
require_relative 'env'

def func(&block)
  MalFunction.new(Proc.new(&block))
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
  if a.type == :list || a.type == :vector
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
  'vector' => func { |*args| Mal.new(:vector, args) },
  'list?' => func { |obj| bool(obj.type == :list) },
  'vector?' => func { |obj| bool(obj.type == :vector) },
  'empty?' => func { |list| bool(list.val.count == 0) },
  'count' => func { |list| Mal.new(:number, (list.type == :list || list.type == :vector) ? list.val.count : 0) },
  'not' => func { |x| bool(x.type == :nil || x.type == :false) },
  'pr-str' => func { |*args| Mal.new(:string, args.map { |x| pr_str(x, true) }.join(' ')) },
  'str' => func { |*args| Mal.new(:string, args.map { |x| pr_str(x, false) }.join('')) },
  'prn' => func { |*args| puts args.map { |x| pr_str(x, true) }.join(' '); Mal.new(:nil, nil) },
  'println' => func { |*args| puts args.map { |x| pr_str(x, false) }.join(' '); Mal.new(:nil, nil) },
  'read-string' => func { |str| read_str(str.val) },
  'slurp' => func { |filename| Mal.new(:string, File.binread(filename.val)) },
  'cons' => func { |x, list| Mal.new(:list, [x] + list.val) },
  'concat' => func { |*args| Mal.new(:list, args.map { |x| x.val }.flatten || []) },
  'nth' => func { |list, n| list.val[n.val] || fail('not found') },
  'first' => func { |list| ((list.type == :list || list.type == :vector) && list.val[0]) || Mal.new(:nil, nil) },
  'rest' => func { |list| Mal.new(:list, list.val[1..-1] || []) },
  'throw' => func { |str| fail(MalException, str) },
  'symbol' => func { |x| Mal.new(:symbol, x.val) },
  'symbol?' => func { |x| bool(x.type == :symbol) },
  'nil?' => func { |x| bool(x.type == :nil) },
  'true?' => func { |x| bool(x.type == :true) },
  'false?' => func { |x| bool(x.type == :false) },
  'map?' => func { |x| bool(x.type == :map) },
  'keyword' => func { |x| Mal.new(:keyword, ":" + x.val) },
  'keyword?' => func { |x| bool(x.type == :keyword) },
  'sequential?' => func { |x| bool(x.type == :list || x.type == :vector) },
  'contains?' => func { |map, x| bool(map.val[x.val]) },
  'get' => func { |map, x| a = map.type == :map ? map.val[x.val] : nil; a.nil? ? Mal.new(:nil, nil) : a[1] },
  'hash-map' => func { |*args| m = args.each_slice(2).map { |a, b| [a.val, [a, b]] }.to_h; Mal.new(:map, m) },
  'assoc' => func { |map, *args| m = map.val.clone; m.merge!(args.each_slice(2).map { |a, b| [a.val, [a, b]] }.to_h); Mal.new(:map, m) },
  'dissoc' => func { |map, *args| m = map.val.clone; args.each { |x| m.delete(x.val) }; Mal.new(:map, m) },
  'keys' => func { |map| Mal.new(:list, map.val.values.map{|x| x[0]})},
  'vals' => func { |map| Mal.new(:list, map.val.values.map{|x| x[1]})},
})
