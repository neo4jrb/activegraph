#require 'spec/support/rspec'

module Neo4jSpecEdition
  def self.current
    edition = ENV['EDITION'] || ENV['ED']
    (edition && !edition.empty?) ? edition.downcase.to_sym : nil
  end
end

RSpec.configure do |c|
  edition =  Neo4jSpecEdition.current

  if edition
    require "neo4j-#{edition}"
    c.filter = { :edition => edition }
  else
    # If no edition profided, we need to exclude spacs tagged with :edition
    c.exclusion_filter = {
      :edition => lambda {|ed| ed.present? }
    }
  end
end
