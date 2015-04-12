require_relative 'types'
TOKENS = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/

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
  read_form Reader.new(tokens)
end

def read_list(reader, start = '(', endd = ')', type=:list)
  reader.next
  val = []
  while (token = reader.peek) != endd
    if token.nil?
      fail "expected '#{endd}', got EOF"
    end
    val << read_form(reader)
  end
  reader.next
  Mal.new(:list, val)
end

def read_atom(reader)
  token = reader.next
  case token
  when 'nil'
    Mal.new(:nil, nil)
  when 'true'
    Mal.new(:true, true)
  when 'false'
    Mal.new(:false, false)
  when /\A-?[0-9]+\z/
    Mal.new(:number, token.to_i)
  when /\A".*"\z/
    Mal.new(:string, token[1..-2].gsub('\n', "\n").gsub('\"', "\""))
  else
    Mal.new(:symbol, token.to_s)
  end
end

def read_form(reader)
  token = reader.peek
  case token[0]
  when "'"
    reader.next
    Mal.new(:list, [Mal.new(:symbol, 'quote'), read_form(reader)])
  when "`"
    reader.next
    Mal.new(:list, [Mal.new(:symbol, 'quasiquote'), read_form(reader)])
  when "~"
    reader.next
    if token[1] == '@'
      Mal.new(:list, [Mal.new(:symbol, 'splice-unquote'), read_form(reader)])
    else
      Mal.new(:list, [Mal.new(:symbol, 'unquote'), read_form(reader)])
    end
  when '('
    read_list(reader)
  when '['
    read_list(reader, '[', ']', :vector)
  else
    read_atom(reader)
  end
end
