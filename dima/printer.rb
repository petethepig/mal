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
  when :string
    if print_readably
      # '"' + mal.val.gsub("\"", '\"').gsub("\n", '\n') + '"'
      mal.val.inspect
    else
      mal.val
    end
  when :list
    "(" + mal.val.map { |x| pr_str(x, print_readably) }.join(" ") + ")"
  end
end
