require_relative "reader"
require_relative "printer"

def _read(str)
  read_str str
end

def _eval(str)
  str
end

def _print(mal)
  pr_str(mal, true)
end


def _rep(str)
  begin
    _print(_eval(_read(str)))
  rescue => e
    print e.message
  end
end

while (print "user> "; line = gets())
  puts _rep(line)
end

