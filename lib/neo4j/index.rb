module Neo4j

  module Index
    def index(field, value=self[field], db=Neo4j.default_db)
      db.lucene.index(self, field.to_s, value)
    end

    def rm_index(field, db=Neo4j.default_db)
      db.lucene.remove_index(self, field.to_s)
    end

  end

end