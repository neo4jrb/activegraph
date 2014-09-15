module UniqueClass
  @@_counter = 0

  def self._unique_random_number
    "#{Time.now.year}#{Time.now.to_i}#{Time.now.usec.to_s[0..2]}".to_i
  end

  def self._unique_name
    @@_counter += 1
    "Model_#{@@_counter}_#{_unique_random_number}"
  end

  def self.create(class_name = nil, &block)
    unique_name = _unique_name
    Class.new do
      Object.const_set(class_name || unique_name, self)
      class_eval &block if block
    end
  end
end
