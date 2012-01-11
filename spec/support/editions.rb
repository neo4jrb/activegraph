module Neo4jSpecEdition
  def self.current
    edition = ENV['EDITION'] || ENV['ED']
    edition ? edition.downcase.to_sym : nil
  end
end

RSpec.configure do |c|
  edition =  Neo4jSpecEdition.current

  if edition
    require "neo4j-#{edition}"
    c.filter = { :edition => edition }
  end
end
