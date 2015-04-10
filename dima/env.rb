class Env
  attr_accessor :data
  attr_accessor :outer

  def initialize(data = {}, outer = nil)
    @data, @outer = data, outer
  end

  def set(k, v)
    @data[k] = v
  end

  def find(k)
    if @data.has_key?(k)
      @data
    elsif @outer
      @outer.find(k)
    end
  end

  def get(k)
    (a = find(k)) && a[k] || fail("'#{k}' not found")
  end
end
