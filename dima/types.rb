class Mal
  attr_reader :val
  def initialize(type, val)
    @type, @val = type, val
  end
end

class MalList < Array
  attr_accessor :meta
end

class MalVector < Array
  attr_accessor :meta
end

class MalMap < Hash
  attr_accessor :meta
end

class MalFunction < Proc
  attr_reader :val
  attr_accessor :ast
  attr_accessor :mame
  attr_accessor :params
  attr_accessor :env
  attr_accessor :is_macro
  attr_accessor :meta
  def initialize(ast=nil, params=nil, env=nil, is_macro=false, &block)
    @type = :function
    @val = self
    @ast, @params, @env, @is_macro = ast, params, env, is_macro
    super(&block)
  end
end

class MalException < StandardError
  attr_reader :val
  attr_accessor :meta
  def initialize(val)
    @type, @val = :exception, val
  end
end
