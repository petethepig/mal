def pr_str(mal, print_readably = false)
  case mal.type
  when :number
    mal.val.to_s
  when :nil, :true, :false
    mal.val.to_s
  when :symbol
    mal.val.to_s
  when :string
    mal.val.inspect
  when :list
    "(" + mal.val.map { |x| pr_str(x) }.join(" ") + ")"
  end
end
