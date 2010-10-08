module Neo4j::TxMethods
  def tx_methods(*methods)
    puts "TX METHODS !"
    methods.each do |method|
      tx_method = "#{method}_in_tx"
      send(:alias_method, tx_method, method)
      puts "tx_method #{method} #{tx_method}"
      send(:define_method, method) do |*args|
        puts "calling #{tx_method} with args #{args.inspect}"
        Neo4j::Rails::Transaction.running? ? send(tx_method, *args) : Neo4j::Rails::Transaction.run { send(tx_method, *args) }
      end
    end
  end
end