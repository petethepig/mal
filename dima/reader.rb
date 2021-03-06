require_relative 'types'
TOKENS = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/

EmptyError = Class.new(StandardError)

class Reader
  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def peek
    @tokens[@pos]
  end

  def next
    peek.tap { @pos += 1 }
  end
end

# returns a list of tokens
def tokenizer(str)
  str.scan(TOKENS).map { |x| x[0] }.select do |t|
    t != '' && t[0] != ';'
  end #.tap {|x| puts x.inspect}
end

def read_str(str)
  tokens = tokenizer(str)
  fail(EmptyError) if tokens.count == 0
  read_form Reader.new(tokens)
end

def read_list(reader, start = '(', endd = ')', type=MalList)
  reader.next
  arr = []
  while (token = reader.peek) != endd
    if token.nil?
      fail "expected '#{endd}', got EOF"
    end
    arr << read_form(reader)
  end
  reader.next
  type.new arr
end

def read_map(reader)
  # reader.next
  # arr = [:'hash-map']
  # while (token = reader.peek) != '}'
  #   if token.nil?
  #     fail "expected '}', got EOF"
  #   end
  #   arr << read_form(reader)
  # end
  # reader.next
  # MalList.new(arr)
  MalMap[*read_list(reader, '{', '}', Array)]
end

def read_atom(reader)
  token = reader.next
  case token
  when 'nil'
    nil
  when 'true'
    true
  when 'false'
    false
  when /\A-?[0-9]+\.[0-9]+\z/
    token.to_f
  when /\A-?[0-9]+\z/
    token.to_i
  when /\A".*"\z/
    token[1..-2].gsub('\n', "\n").gsub('\"', "\"")
  when /\A:/
    "\u029e" + token[1..-1]
  else
    token.to_sym
  end
end

def read_form(reader)
  token = reader.peek
  return Mal.new(:nil, nil) unless token
  case token[0]
  when "'"
    reader.next
    MalList.new([:quote, read_form(reader)])
  when "`"
    reader.next
    MalList.new([:quasiquote, read_form(reader)])
  when "~"
    reader.next
    if token[1] == '@'
      MalList.new([:'splice-unquote', read_form(reader)])
    else
      MalList.new([:unquote, read_form(reader)])
    end
  when '@'
    reader.next
    MalList.new([:'deref', read_form(reader)])
  when '^'
    reader.next
    meta = read_form(reader)
    val = read_form(reader)
    MalList.new([:'with-meta', val, meta])
  when '('
    read_list(reader)
  when '['
    read_list(reader, '[', ']', MalVector)
  when '{'
    read_map(reader)
  else
    read_atom(reader)
  end
end
