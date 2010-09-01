module MyMacros
  def return_value(&block)
    clazz = describes
#    subject{clazz.new(*@_args)}
    #it desc do
     # puts "SUBJECT #{subject} #{subject.class}"
    puts "2. SELF #{self.methods}"

    self.instance_eval(&block)
    #end
  end

  def static_method(method, param, &block)
    args = param[:args]
    context "##{method}", describe_args(args) do
      @_args = args
      clazz = describes

      subject{clazz.new(*@_args)}

      self.instance_eval(&block)
      puts "1. SELF #{self.methods}"
    end
  end

  def describe_args(args)
    "(#{args.collect { |x| "#{x}:#{x.class}" }.join(',')})"
  end
end


describe Foo do
  extend MyMacros

  static_method(:new, :args=>[]) do
    it("xxx") {puts "HEJ #{subject}"}
    return_value do
      it { puts "EMPTY = #{subject.class} #{subject.inspect}" }#should be_empty}
    end
#    return_value("must be empty") { puts "SUBJECT=#{subject.inspect}, #{subject.class}"; should be_empty}
#    it "should ..." do
#      puts "SUBJECT #{subject.class}"
      #return_value
#    end
    #return_value
    #return_value { should be_empty }
  end

end
