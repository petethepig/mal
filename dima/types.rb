class Mal
  attr_reader :type
  attr_reader :val
  def initialize(type, val)
    @type, @val = type, val
  end
end

class MalFunction < Mal
  attr_reader :ast
  attr_reader :params
  attr_reader :env
  attr_accessor :is_macro
  def initialize(val, ast=nil, params=nil, env=nil, is_macro=false)
    @type, @val, @ast, @params, @env, @is_macro = :function, val, ast, params, env, is_macro
  end
end
