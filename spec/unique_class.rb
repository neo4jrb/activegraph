module UniqueClass
  @@_counter = 1

  def self.set(klass, name=nil)
    name ||= "Model_#{@@_counter}"
    @@_counter += 1
    klass.class_eval <<-RUBY
	def self.to_s
	  "#{name}"
	end
    RUBY
    Kernel.const_set(name, klass)
    klass
  end

  def self.create(class_name=nil, &block)
    clazz = Class.new
    set(clazz, class_name)
    clazz.class_eval &block
    clazz
  end
end
