class Mal
  attr_reader :type
  attr_reader :val
  def initialize(type, val)
    @type, @val = type, val
  end
end
