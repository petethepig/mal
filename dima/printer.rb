def pr_str(mal, print_readably = false)
  case mal
  when MalFunction
    "#<function #{mal}>"
  when Numeric
    mal.to_s
  when NilClass
    'nil'
  when TrueClass, FalseClass
    mal.to_s
  when Symbol
    mal.to_s
  when MalException
    pr_str(mal.val, print_readably)
  when MalMap
    str = mal.to_a.map {|a, b| [pr_str(a, print_readably), pr_str(b, print_readably)]}.flatten.join(" ")
    "{" + str + "}"
  when String
    if mal[0] == "\u029e"
      ':' + mal[1..-1]
    elsif print_readably
      # '"' + mal.val.gsub("\"", '\"').gsub("\n", '\n') + '"'
      mal.inspect
    else
      mal
    end
  when MalAtom
    "(atom #{pr_str(mal.val, print_readably)})"
  when MalList
    "(" + mal.map { |x| pr_str(x, print_readably) }.join(" ") + ")"
  when MalVector
    "[" + mal.map { |x| pr_str(x, print_readably) }.join(" ") + "]"
  else
    "unknown: #{mal}"
  end
end
