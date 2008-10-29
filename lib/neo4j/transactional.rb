module Neo4j
  
  #
  # Includes support for wrapping a method in a Neo4j transaction.
  #
  module TransactionalMixin
  
    def transactional(*methods)
      methods.each do |name|
        orig_name = (name.to_s == '<<') ? '_append' : "_original_#{name}"
        self.send :alias_method, orig_name, name


        self.instance_eval %Q/
      define_method('#{name}'.to_sym) do |*args|
        Neo4j::Transaction.run {
          #{orig_name} *args
        }
      end
        / #,  __FILE__, __LINE__)
      end
    end
  end
end