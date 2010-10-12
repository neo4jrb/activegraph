module Neo4j
  module Rails
    module TxMethods
      def tx_methods(*methods)
        methods.each do |method|
          tx_method = "#{method}_in_tx"
          send(:alias_method, tx_method, method)
          send(:define_method, method) do |*args|
            Neo4j::Rails::Transaction.running? ? send(tx_method, *args) : Neo4j::Rails::Transaction.run { send(tx_method, *args) }
          end
        end
      end
    end
  end
end
