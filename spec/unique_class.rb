module UniqueClass
  @counter = 1

  class << self
    def _unique_random_number
      "#{Time.now.year}#{Time.now.to_i}#{Time.now.usec.to_s[0..2]}".to_i
    end

    def set(klass, name = nil)
      name ||= "Model_#{@counter}_#{_unique_random_number}"
      @counter += 1
      klass.class_eval <<-RUBY
        def self.to_s
          "#{name}"
        end
      RUBY
      # Object.send(:remove_const, name) if Object.const_defined?(name)
      Object.const_set(name, klass) # unless Kernel.const_defined?(name)
      klass
    end

    def create(class_name = nil, &block)
      clazz = Class.new
      set(clazz, class_name)
      clazz.class_eval(&block) if block
      clazz
    end
  end
end
