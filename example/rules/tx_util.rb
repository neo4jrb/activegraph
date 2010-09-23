def finish_tx
  return unless @tx
  @tx.success
  @tx.finish
  @tx = nil
end

def new_tx
  finish_tx if @tx
  @tx = Neo4j::Transaction.new
end
