module Neo4j
  
  #
  # Includes support for wrapping a method in a Neo4j transaction.
  # If the constant NEO4J_AUTO_TX is defined then the specified methods will be wrapped in a transaction.
  #
  module TransactionalMixin
  
    def transactional(*methods)
      return unless defined? NEO4J_AUTO_TX
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