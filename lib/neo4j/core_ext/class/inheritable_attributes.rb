# This is copied from Rails Active Support since it has been depricated and I still need it
class Class # :nodoc:
  def class_inheritable_reader(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}                                # def self.after_add
          read_inheritable_attribute(:#{sym})          #   read_inheritable_attribute(:after_add)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}                                     # def after_add
          self.class.#{sym}                            #   self.class.after_add
        end                                            # end
        " unless options[:instance_reader] == false }  # # the reader above is generated unless options[:instance_reader] == false
      EOS
    end
  end

  def class_inheritable_writer(*syms)
    options = syms.extract_options!
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)                          # def self.color=(obj)
          write_inheritable_attribute(:#{sym}, obj)    #   write_inheritable_attribute(:color, obj)
        end                                            # end
                                                       #
        #{"                                            #
        def #{sym}=(obj)                               # def color=(obj)
          self.class.#{sym} = obj                      #   self.class.color = obj
        end                                            # end
        " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
      EOS
    end
  end
end
