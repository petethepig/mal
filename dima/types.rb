class Mal
  attr_reader :type
  attr_reader :val
  attr_reader :ast
  attr_reader :params
  attr_reader :env
  def initialize(type, val, ast=nil,params=nil,env=nil)
    @type, @val, @ast, @params, @env = type, val, ast, params, env
  end
end
