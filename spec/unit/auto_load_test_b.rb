module AutoLoadTest
  class MyWrapperClass
    include Neo4j::ActiveNode
    property :some_prop
  end
end
