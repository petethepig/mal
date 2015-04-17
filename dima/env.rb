class Env
  attr_accessor :data
  attr_accessor :outer

  def initialize(data = {}, outer = nil, binds = [], exprs = [])
    @data, @outer = data, outer
    binds.each_index do |i|
      @data[binds[i]] = exprs[i]
    end
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
    if (a = find(k))
      a[k]
    else
      fail("'#{k}' not found")
    end
  end
end
