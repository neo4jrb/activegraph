module Neo4j::Rails

  class DirtyTxListener # :nodoc:
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @fields = {}
    end

    def after_commit(data, state)
      #puts "before commit"
    end

    def after_rollback(data, state)
    end

    def before_commit(data)
      data.assigned_node_properties.each { |tx_data| update_index(tx_data) if trigger_update?(tx_data) }
    end


    def self.on_property_changed(node, key, old_value, new_value)
      # make model dirty since it is changed
      ActiveModelFactory.instance.dirty_node!(node.neo_id)
    end

    def self.on_tx_finished(tx)
      # make all models clean again
      ActiveModelFactory.instance.clean!
    end

  end

end


def create
  Person.new_value
end

def update
  person = Person.find()
  person.name = 'asdasd'
  pelle = Person.new
  person.friends << pelle
  Neo4j::Transaction.finish # or Neo4j.save does both Transaction.finish and Transaction.new
  person.valid?
  pelle.valid?
end