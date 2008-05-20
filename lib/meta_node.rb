module Neo
  class MetaNode < Node
    properties :meta_classname # the name of the ruby class it represent
    relations :instances
  end
end