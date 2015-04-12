def pr_str(mal, print_readably = false)
  case mal.type
  when :function
    '#<function>'
  when :number
    mal.val.to_s
  when :nil
    'nil'
  when :true, :false
    mal.val.to_s
  when :symbol
    mal.val.to_s
  when :keyword
    mal.val.to_s
  when :exception
    pr_str(mal.val, print_readably)
  when :map
    str = mal.val.to_a.map {|a, b| [pr_str(b[0], print_readably), pr_str(b[1], print_readably)]}.flatten.join(" ")
    "{" + str + "}"
  when :string
    if print_readably
      # '"' + mal.val.gsub("\"", '\"').gsub("\n", '\n') + '"'
      mal.val.inspect
    else
      mal.val
    end
  when :list
    "(" + mal.val.map { |x| pr_str(x, print_readably) }.join(" ") + ")"
  when :vector
    "[" + mal.val.map { |x| pr_str(x, print_readably) }.join(" ") + "]"
  end
end
