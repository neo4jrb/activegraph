class DummyNode
  attr_accessor :props

  def initialize
    @props = {}
  end

  def set_property(p, v)
    @props[p] = v
  end

   def property?(p)
    !@props[p].nil?
  end
end
