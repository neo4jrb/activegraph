module Neo4j::NodeMixin
  def to_model
    Neo4j::ActiveModel::ActiveModelFactory.instance.to_model(self)
  end


end
