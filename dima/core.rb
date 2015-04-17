require_relative 'types'
require_relative 'reader'
require_relative 'printer'
require_relative 'env'

def func(&block)
  MalFunction.new(&block)
end

def bool(a)
  !!a
end

def equality(a, b)
  if a.is_a?(Array) && b.is_a?(Array)
    return false if a.count != b.count
    a.each_index do |i|
      if !equality(a[i], b[i])
        return false
      end
      true
    end
  else
    a == b
  end
end

NS = Env.new({
  :'=' => func { |a, b| equality(a, b) },
  :> => func { |a, b| a > b },
  :>= => func { |a, b| a >= b },
  :< => func { |a, b| a < b },
  :<= => func { |a, b| a <= b },
  :+ => func { |a, b| a + b },
  :- => func { |a, b| a - b },
  :* => func { |a, b| a * b },
  :/ => func { |a, b| a / b },
  :list => func { |*args| MalList.new(args) },
  :vector => func { |*args| MalVector.new(args) },
  :list? => func { |obj| obj.is_a?(MalList) },
  :vector? => func { |obj| obj.is_a?(MalVector) },
  :empty? => func { |list| list.count == 0 },
  :count => func { |list| list.is_a?(Array) ? list.count : 0 },
  :not => func { |x| x == nil || x == false },
  :'pr-str' => func { |*args| args.map { |x| pr_str(x, true) }.join(' ') },
  :str => func { |*args| args.map { |x| pr_str(x, false) }.join('') },
  :prn => func { |*args| puts args.map { |x| pr_str(x, true) }.join(' '); nil },
  :println => func { |*args| puts args.map { |x| pr_str(x, false) }.join(' '); nil },
  :'read-string' => func { |str| read_str(str) },
  :slurp => func { |filename| File.binread(filename) },
  :cons => func { |x, list| MalList.new([x] + list) },
  :concat => func { |*args| MalList.new(args.flatten || []) },
  :nth => func { |list, n| list[n] || fail('not found') },
  :first => func { |list| (list.is_a?(Array) && list[0]) || nil },
  :rest => func { |list| list[1..-1] || [] },
  :throw => func { |x| fail(MalException, x) },
  :symbol => func { |x| x.to_sym },
  :symbol? => func { |x| x.is_a?(Symbol) },
  :nil? => func { |x| x.nil? },
  :true? => func { |x| x },
  :false? => func { |x| !x },
  :map? => func { |x| x.is_a?(MalMap) },
  :keyword => func { |x| "\u029e" + x },
  :keyword? => func { |x| x[0] == "\u029e" },
  :sequential? => func { |x| x.is_a?(Array) },
  :contains? => func { |map, x| map[x] },
  :get => func { |map, x| map[x] },
  :'hash-map' => func { |*args| MalMap[*args] },
  :assoc => func { |map, *args| map.merge(args.each_slice(2).to_h) },
  :dissoc => func { |map, *args| m = map.clone; args.each { |x| m.delete(x) }; m },
  :keys => func { |map| MalList.new(map.keys) },
  :vals => func { |map| MalList.new(map.values) },
  :apply => func { |func, *args| list = args.pop; func.call(*(args + list)) },
  :map => func { |func, list| MalList.new(list.map { |x| func.call(x) }) },
  :readline => func { |prompt| Readline.readline(prompt, true) },
  :atom => func { |x| MalAtom.new(x) },
  :deref => func { |x| x.val },
  :reset! => func { |x, val| x.val = val },
  :swap! => func { |x, func, *args| x.val = func.call(*([x.val] + args)) },
  :'with-meta' => func { |x, meta| x = x.clone; x.meta = meta; x },
  :'meta' => func { |x| x.meta },
  :'conj' => func { |list, *args| list.is_a?(MalList) ? MalList.new(args.reverse + list) : MalVector.new(list + args) },
})
