module Neo4j

  # See http://wiki.neo4j.org/content/Indexing_with_IndexService
  module Index
    def index(field, db=Neo4j.db)
      db.lucene.index(self, field.to_s, self[field])
    end

    def rm_index(field, db=Neo4j.db)
      db.lucene.remove_index(self, field.to_s)
    end

  end

end