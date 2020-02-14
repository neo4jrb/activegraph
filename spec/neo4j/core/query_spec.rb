require 'spec_helper'

class DocGenerator
  QUERY_DOCS_PATH = File.join('..', 'neo4j', 'docs')

  RST_HEADER_ORDER = %w[- ~ ^]

  def initialize(filename)
    @filename = filename
    @last_headers = []

    base_path = File.join(QUERY_DOCS_PATH, "#{filename}.base")
    @enabled = ENV['GENERATE_QUERY_DOCS'] && File.exist?(base_path)

    return if !@enabled

    path = File.join(QUERY_DOCS_PATH, 'QueryClauseMethods.rst')
    `cp #{base_path} #{path}`

    @file = File.open(path, 'a')
  end

  def get_headers(context_class)
    parts = context_class.name.split('::')
    headers = (3..parts.size - 1).map { |i| Kernel.const_get(parts[0, i].join('::')).description }

    @first_different_index = headers.each_with_index.detect do |header, index|
      @last_headers[index] != header
    end

    @last_headers = headers

    return if !@first_different_index

    headers[@first_different_index[1]..-1]
  end

  def add_headers(context_class)
    headers = get_headers(context_class)

    return if headers.nil?

    headers.each_with_index do |header, index|
      @file.puts header
      @file.puts RST_HEADER_ORDER[index + @first_different_index[1]] * header.size
      @file.puts
    end
  end

  def add_query_doc_line(context_class, query_code, cypher, params = {})
    return if !@enabled

    add_headers(context_class)

    @file.puts <<-RST.strip_heredoc
      :Ruby:
        .. code-block:: ruby

          #{query_code}

      :Cypher:
        .. code-block:: cypher

          #{cypher}

RST

    @file.puts "**Parameters:** ``#{params.inspect}``" unless params.empty?
    @file.puts
    @file.puts '------------'
    @file.puts
  end
end

describe Neo4j::Core::Query do
  before(:all) do
    @doc_generator = DocGenerator.new('QueryClauseMethods.rst')
  end

  describe 'options' do
    let(:query) { Neo4j::Core::Query.new(parser: 2.0) }

    it 'should generate a per-query cypher parser version' do
      expect(query.to_cypher).to eq('CYPHER 2.0')
    end

    describe 'subsequent call' do
      let(:query) { super().match('q:Person') }

      it 'should combine the parser version with the rest of the query' do
        expect(query.to_cypher).to eq('CYPHER 2.0 MATCH q:Person')
      end
    end
  end

  class Person
  end

  describe 'batch finding' do
    let!(:session) { test_driver_adaptor(test_bolt_url) }
    let(:query_object) { Neo4j::Core::Query.new }

    before(:each) do
      5.times do
        Neo4j::Transaction.query('CREATE (n:Foo {uuid: $uuid})', uuid: SecureRandom.uuid)
      end
      2.times do
        Neo4j::Transaction.query('CREATE (n:Bar {uuid: $uuid})', uuid: SecureRandom.uuid)
      end
    end

    %i[uuid neo_id].each do |primary_key|
      describe "find_in_batches with #{primary_key}" do
        {
          1 => 5,
          2 => 3,
          3 => 2,
          4 => 2,
          5 => 1,
          6 => 1
        }.each do |batch_size, expected_yields|
          context "batch_size of #{batch_size}" do
            it "yields #{expected_yields} times" do
              expect do |block|
                query_object.match(f: :Foo).return(:f).find_in_batches(:f, primary_key, batch_size: batch_size, &block)
              end.to yield_control.exactly(expected_yields).times
            end
          end
        end
      end

      describe "find_each with #{primary_key}" do
        {
          1 => 5,
          2 => 5,
          3 => 5,
          4 => 5,
          5 => 5,
          6 => 5
        }.each do |batch_size, expected_yields|
          context "batch_size of #{batch_size}" do
            it "yields #{expected_yields} times" do
              expect do |block|
                query_object.match(f: :Foo).return(:f).find_each(:f, primary_key, batch_size: 2, &block)
              end.to yield_control.exactly(5).times
            end
          end
        end
      end
    end
  end

  describe 'DEFINED_CLAUSES' do
    it 'includes a key for each clause' do
      Neo4j::Core::Query::METHODS.each do |clause_string|
        expect(Neo4j::Core::Query::DEFINED_CLAUSES).to have_key(clause_string.to_sym)
      end
    end
  end

  describe '#clause?' do
    subject(:clause) { query.clause?(clause_method) }

    context 'checking for where' do
      let(:clause_method) { :where }

      context 'Query with a where' do
        let(:query) { Neo4j::Core::Query.new.where(true) }
        it { should be(true) }
      end

      context 'Query with an order' do
        let(:query) { Neo4j::Core::Query.new.order(:foo) }
        it { should be(false) }
      end

      context 'Query with a where and an order' do
        let(:query) { Neo4j::Core::Query.new.where('true').order(:foo) }
        it { should be(true) }
      end
    end
  end


  def add_query_doc_line(cypher, params = {})
    @doc_generator.add_query_doc_line(self.class, self.class.description, cypher, params)
  end

  def expects_cypher(cypher, params = {})
    query = eval("Neo4j::Core::Query.new#{self.class.description}", binding, __FILE__, __LINE__) # rubocop:disable Security/Eval
    add_query_doc_line(cypher, params)

    expect(query.to_cypher).to eq(cypher)

    query_params = query.send(:merge_params) || {}
    expect(query_params).to eq(params) unless params.empty? && query_params.empty?
  end

  def self.it_generates(cypher, params = {})
    it "generates #{cypher}" do
      expects_cypher(cypher, params)
    end
  end

  # MATCH

  describe '#match' do
    describe ".match('n')" do
      it_generates 'MATCH n'
    end

    describe '.match(:n)' do
      it_generates 'MATCH (n)'
    end

    describe '.match(n: Person)' do
      it_generates 'MATCH (n:`Person`)'
    end

    describe ".match(n: 'Person')" do
      it_generates 'MATCH (n:`Person`)'
    end

    describe ".match(n: ':Person')" do
      it_generates 'MATCH (n:Person)'
    end

    describe '.match(n: :Person)' do
      it_generates 'MATCH (n:`Person`)'
    end

    describe '.match(n: [:Person, "Animal"])' do
      it_generates 'MATCH (n:`Person`:`Animal`)'
    end

    describe ".match(n: ' :Person')" do
      it_generates 'MATCH (n:Person)'
    end

    describe '.match(n: nil)' do
      it_generates 'MATCH (n)'
    end

    describe ".match(n: 'Person {name: \"Brian\"}')" do
      it_generates 'MATCH (n:Person {name: "Brian"})'
    end

    describe ".match(n: {name: 'Brian', age: 33})" do
      it_generates 'MATCH (n {name: $n_name, age: $n_age})', n_name: 'Brian', n_age: 33
    end

    describe ".match(n: {Person: {name: 'Brian', age: 33}})" do
      it_generates 'MATCH (n:`Person` {name: $n_Person_name, age: $n_Person_age})', n_Person_name: 'Brian', n_Person_age: 33
    end

    describe ".match('n--o')" do
      it_generates 'MATCH n--o'
    end

    describe ".match('n--o', 'o--p')" do
      it_generates 'MATCH n--o, o--p'
    end

    describe ".match('n--o').match('o--p')" do
      it_generates 'MATCH n--o, o--p'
    end
  end

  # OPTIONAL MATCH

  describe '#optional_match' do
    describe '.optional_match(n: Person)' do
      it_generates 'OPTIONAL MATCH (n:`Person`)'
    end

    describe ".match('m--n').optional_match('n--o').match('o--p')" do
      it_generates 'MATCH m--n, o--p OPTIONAL MATCH n--o'
    end
  end

  # CALL

  describe '#call' do
    describe ".call('db.constraints()')" do
      it_generates 'CALL db.constraints()'
    end
  end

  # USING

  describe '#using' do
    describe ".using('INDEX m:German(surname)')" do
      it_generates 'USING INDEX m:German(surname)'
    end

    describe ".using('SCAN m:German')" do
      it_generates 'USING SCAN m:German'
    end

    describe ".using('INDEX m:German(surname)').using('SCAN m:German')" do
      it_generates 'USING INDEX m:German(surname) USING SCAN m:German'
    end
  end


  # WHERE

  describe '#where' do
    describe '.where()' do
      it_generates ''
    end

    describe '.where({})' do
      it_generates ''
    end

    describe ".where('q.age > 30')" do
      it_generates 'WHERE (q.age > 30)'
    end

    describe ".where('q.age' => 30)" do
      it_generates 'WHERE (q.age = $q_age)', q_age: 30
    end

    describe ".where('q.age' => [30, 32, 34])" do
      it_generates 'WHERE (q.age IN $q_age)', q_age: [30, 32, 34]
    end

    describe ".where('q.age IN $age', age: [30, 32, 34])" do
      it_generates 'WHERE (q.age IN $age)', age: [30, 32, 34]
    end

    describe ".where('(q.age IN $age)', age: [30, 32, 34])" do
      it_generates 'WHERE (q.age IN $age)', age: [30, 32, 34]
    end

    describe ".where('q.name =~ ?', '.*test.*')" do
      it_generates 'WHERE (q.name =~ $question_mark_param)', question_mark_param: '.*test.*'
    end

    describe ".where('(q.name =~ ?)', '.*test.*')" do
      it_generates 'WHERE (q.name =~ $question_mark_param)', question_mark_param: '.*test.*'
    end

    describe ".where('(LOWER(str(q.name)) =~ ?)', '.*test.*')" do
      it_generates 'WHERE (LOWER(str(q.name)) =~ $question_mark_param)', question_mark_param: '.*test.*'
    end

    describe ".where('q.age IN ?', [30, 32, 34])" do
      it_generates 'WHERE (q.age IN $question_mark_param)', question_mark_param: [30, 32, 34]
    end

    describe ".where('q.age IN ?', [30, 32, 34]).where('q.age != ?', 60)" do
      it_generates 'WHERE (q.age IN $question_mark_param) AND (q.age != $question_mark_param2)', question_mark_param: [30, 32, 34], question_mark_param2: 60
    end


    describe '.where(q: {age: [30, 32, 34]})' do
      it_generates 'WHERE (q.age IN $q_age)', q_age: [30, 32, 34]
    end

    describe ".where('q.age' => nil)" do
      it_generates 'WHERE (q.age IS NULL)'
    end

    describe '.where(q: {age: nil})' do
      it_generates 'WHERE (q.age IS NULL)'
    end

    describe '.where(q: {neo_id: 22})' do
      it_generates 'WHERE (ID(q) = $ID_q)', ID_q: 22
    end

    describe ".where(q: {age: 30, name: 'Brian'})" do
      it_generates 'WHERE (q.age = $q_age AND q.name = $q_name)', q_age: 30, q_name: 'Brian'
    end

    describe ".where(q: {age: 30, name: 'Brian'}).where('r.grade = 80')" do
      it_generates 'WHERE (q.age = $q_age AND q.name = $q_name) AND (r.grade = 80)', q_age: 30, q_name: 'Brian'
    end

    describe '.where(q: {name: /Brian.*/i})' do
      it_generates 'WHERE (q.name =~ $q_name)', q_name: '(?i)Brian.*'
    end

    describe '.where(name: /Brian.*/i)' do
      it_generates 'WHERE (name =~ $name)', name: '(?i)Brian.*'
    end

    describe '.where(name: /Brian.*/i).where(name: /Smith.*/i)' do
      it_generates 'WHERE (name =~ $name) AND (name =~ $name2)', name: '(?i)Brian.*', name2: '(?i)Smith.*'
    end

    describe '.where(q: {age: (30..40)})' do
      it_generates 'WHERE (q.age >= $q_age_range_min AND q.age <= $q_age_range_max)', q_age_range_min: 30, q_age_range_max: 40
    end

    # Non-integer ranges
    describe '.where(q: { created_at: 0.0...5.0 })' do
      it_generates 'WHERE (q.created_at >= $q_created_at_range_min AND q.created_at < $q_created_at_range_max)',
                   q_created_at_range_min: 0.0,
                   q_created_at_range_max: 5.0
    end

    describe '.where(q: { created_at: Date.new(2017, 6, 1)...Date.new(2017, 6, 3) })' do
      it_generates 'WHERE (q.created_at >= $q_created_at_range_min AND q.created_at < $q_created_at_range_max)',
                   q_created_at_range_min: Date.new(2017, 6, 1),
                   q_created_at_range_max: Date.new(2017, 6, 3)
    end

    describe '.where(q: { created_at: Date.new(2017, 6, 1)..Date.new(2017, 6, 3) })' do
      it_generates 'WHERE (q.created_at >= $q_created_at_range_min AND q.created_at <= $q_created_at_range_max)',
                   q_created_at_range_min: Date.new(2017, 6, 1),
                   q_created_at_range_max: Date.new(2017, 6, 3)
    end
  end

  describe '#where_not' do
    describe '.where_not()' do
      it_generates ''
    end

    describe '.where_not({})' do
      it_generates ''
    end

    describe ".where_not('q.age > 30')" do
      it_generates 'WHERE NOT(q.age > 30)'
    end

    describe ".where_not('q.age' => 30)" do
      it_generates 'WHERE NOT(q.age = $q_age)', q_age: 30
    end

    describe ".where_not('q.age IN ?', [30, 32, 34])" do
      it_generates 'WHERE NOT(q.age IN $question_mark_param)', question_mark_param: [30, 32, 34]
    end

    describe ".where_not(q: {age: 30, name: 'Brian'})" do
      it_generates 'WHERE NOT(q.age = $q_age AND q.name = $q_name)', q_age: 30, q_name: 'Brian'
    end

    describe '.where_not(q: {name: /Brian.*/i})' do
      it_generates 'WHERE NOT(q.name =~ $q_name)', q_name: '(?i)Brian.*'
    end


    describe ".where('q.age > 10').where_not('q.age > 30')" do
      it_generates 'WHERE (q.age > 10) AND NOT(q.age > 30)'
    end

    describe ".where_not('q.age > 30').where('q.age > 10')" do
      it_generates 'WHERE NOT(q.age > 30) AND (q.age > 10)'
    end
  end

  describe '#match_nodes' do
    context 'one node object' do
      let(:node_object) { double(neo_id: 246) }

      describe '.match_nodes(var: node_object)' do
        it_generates 'MATCH (var) WHERE (ID(var) = $ID_var)', ID_var: 246
      end

      describe '.optional_match_nodes(var: node_object)' do
        it_generates 'OPTIONAL MATCH (var) WHERE (ID(var) = $ID_var)', ID_var: 246
      end
    end

    context 'integer' do
      describe '.match_nodes(var: 924)' do
        it_generates 'MATCH (var) WHERE (ID(var) = $ID_var)', ID_var: 924
      end
    end

    context 'two node objects' do
      let(:user) { double(neo_id: 246) }
      let(:post) { double(neo_id: 123) }

      describe '.match_nodes(user: user, post: post)' do
        it_generates 'MATCH (user), (post) WHERE (ID(user) = $ID_user) AND (ID(post) = $ID_post)', ID_user: 246, ID_post: 123
      end
    end

    context 'node object and integer' do
      let(:user) { double(neo_id: 246) }

      describe '.match_nodes(user: user, post: 652)' do
        it_generates 'MATCH (user), (post) WHERE (ID(user) = $ID_user) AND (ID(post) = $ID_post)', ID_user: 246, ID_post: 652
      end
    end
  end

  # UNWIND

  describe '#unwind' do
    describe ".unwind('val AS x')" do
      it_generates 'UNWIND val AS x'
    end

    describe '.unwind(x: :val)' do
      it_generates 'UNWIND val AS x'
    end

    describe ".unwind(x: 'val')" do
      it_generates 'UNWIND val AS x'
    end

    describe '.unwind(x: [1,3,5])' do
      it_generates 'UNWIND [1, 3, 5] AS x'
    end

    describe ".unwind(x: [1,3,5]).unwind('val as y')" do
      it_generates 'UNWIND [1, 3, 5] AS x UNWIND val as y'
    end
  end


  # RETURN

  describe '#return' do
    describe ".return('q')" do
      it_generates 'RETURN q'
    end

    describe '.return(:q)' do
      it_generates 'RETURN q'
    end

    describe ".return('q.name, q.age')" do
      it_generates 'RETURN q.name, q.age'
    end

    describe '.return(q: [:name, :age], r: :grade)' do
      it_generates 'RETURN q.name, q.age, r.grade'
    end

    describe '.return(q: :neo_id)' do
      it_generates 'RETURN ID(q)'
    end

    describe '.return(q: [:neo_id, :prop])' do
      it_generates 'RETURN ID(q), q.prop'
    end
  end

  # ORDER BY

  describe '#order' do
    describe ".order('q.name')" do
      it_generates 'ORDER BY q.name'
    end

    describe ".order_by('q.name')" do
      it_generates 'ORDER BY q.name'
    end

    describe ".order('q.age', 'q.name DESC')" do
      it_generates 'ORDER BY q.age, q.name DESC'
    end

    describe '.order(q: :age)' do
      it_generates 'ORDER BY q.age'
    end

    describe '.order(q: :neo_id)' do
      it_generates 'ORDER BY ID(q)'
    end

    describe '.order(q: [:age, {name: :desc}])' do
      it_generates 'ORDER BY q.age, q.name DESC'
    end

    describe '.order(q: [:age, {neo_id: :desc}])' do
      it_generates 'ORDER BY q.age, ID(q) DESC'
    end

    describe '.order(q: [:age, {name: :desc, grade: :asc}])' do
      it_generates 'ORDER BY q.age, q.name DESC, q.grade ASC'
    end

    describe '.order(q: [:age, {name: :desc, neo_id: :asc}])' do
      it_generates 'ORDER BY q.age, q.name DESC, ID(q) ASC'
    end

    describe '.order(q: {age: :asc, name: :desc})' do
      it_generates 'ORDER BY q.age ASC, q.name DESC'
    end

    describe '.order(q: {age: :asc, neo_id: :desc})' do
      it_generates 'ORDER BY q.age ASC, ID(q) DESC'
    end

    describe ".order(q: [:age, 'name desc'])" do
      it_generates 'ORDER BY q.age, q.name desc'
    end

    describe ".order(q: [:neo_id, 'name desc'])" do
      it_generates 'ORDER BY ID(q), q.name desc'
    end
  end


  # LIMIT

  describe '#limit' do
    describe '.limit(3)' do
      it_generates 'LIMIT $limit_3', limit_3: 3
    end

    describe ".limit('3')" do
      it_generates 'LIMIT $limit_3', limit_3: 3
    end

    describe '.limit(3).limit(5)' do
      it_generates 'LIMIT $limit_5', limit_3: 3, limit_5: 5
    end

    describe '.limit(nil)' do
      it_generates ''
    end
  end

  # SKIP

  describe '#skip' do
    describe '.skip(5)' do
      it_generates 'SKIP $skip_5', skip_5: 5
    end

    describe ".skip('5')" do
      it_generates 'SKIP $skip_5', skip_5: 5
    end

    describe '.skip(5).skip(10)' do
      it_generates 'SKIP $skip_10', skip_5: 5, skip_10: 10
    end

    describe '.offset(6)' do
      it_generates 'SKIP $skip_6', skip_6: 6
    end
  end

  # WITH

  %w[with with_distinct].each do |method_name|
    clause = method_name.upcase.tr('_', ' ')

    describe "##{method_name}" do
      describe ".#{method_name}('n.age AS age')" do
        it_generates "#{clause} n.age AS age"
      end

      describe ".#{method_name}('n.age AS age', 'count(n) as c')" do
        it_generates "#{clause} n.age AS age, count(n) as c"
      end

      describe ".#{method_name}(['n.age AS age', 'count(n) as c'])" do
        it_generates "#{clause} n.age AS age, count(n) as c"
      end

      describe ".#{method_name}(age: 'n.age')" do
        it_generates "#{clause} n.age AS age"
      end
    end
  end

  # CREATE, CREATE UNIQUE, and MERGE should all work exactly the same

  describe '#create' do
    describe ".create('(:Person)')" do
      it_generates 'CREATE (:Person)'
    end

    describe '.create(:Person)' do
      it_generates 'CREATE (:Person)'
    end

    describe '.create(age: 41, height: 70)' do
      it_generates 'CREATE ( {age: $age, height: $height})', age: 41, height: 70
    end

    describe '.create(Person: {age: 41, height: 70})' do
      it_generates 'CREATE (:`Person` {age: $Person_age, height: $Person_height})', Person_age: 41, Person_height: 70
    end

    describe '.create(q: {Person: {age: 41, height: 70}})' do
      it_generates 'CREATE (q:`Person` {age: $q_Person_age, height: $q_Person_height})', q_Person_age: 41, q_Person_height: 70
    end

    describe '.create(q: {Person: {age: nil, height: 70}})' do
      it_generates 'CREATE (q:`Person` {age: $q_Person_age, height: $q_Person_height})', q_Person_age: nil, q_Person_height: 70
    end

    describe ".create(q: {:'Child:Person' => {age: 41, height: 70}})" do
      it_generates 'CREATE (q:`Child:Person` {age: $q_Child_Person_age, height: $q_Child_Person_height})', q_Child_Person_age: 41, q_Child_Person_height: 70
    end

    describe ".create(:'Child:Person' => {age: 41, height: 70})" do
      it_generates 'CREATE (:`Child:Person` {age: $Child_Person_age, height: $Child_Person_height})', Child_Person_age: 41, Child_Person_height: 70
    end

    describe '.create(q: {[:Child, :Person] => {age: 41, height: 70}})' do
      it_generates 'CREATE (q:`Child`:`Person` {age: $q_Child_Person_age, height: $q_Child_Person_height})', q_Child_Person_age: 41, q_Child_Person_height: 70
    end

    describe '.create([:Child, :Person] => {age: 41, height: 70})' do
      it_generates 'CREATE (:`Child`:`Person` {age: $Child_Person_age, height: $Child_Person_height})', Child_Person_age: 41, Child_Person_height: 70
    end
  end

  describe '#create_unique' do
    describe ".create_unique('(:Person)')" do
      it_generates 'MERGE (:Person)'
    end

    describe '.create_unique(:Person)' do
      it_generates 'MERGE (:Person)'
    end

    describe '.create_unique(age: 41, height: 70)' do
      it_generates 'MERGE ( {age: $age, height: $height})', age: 41, height: 70
    end

    describe '.create_unique(Person: {age: 41, height: 70})' do
      it_generates 'MERGE (:`Person` {age: $Person_age, height: $Person_height})', Person_age: 41, Person_height: 70
    end

    describe '.create_unique(q: {Person: {age: 41, height: 70}})' do
      it_generates 'MERGE (q:`Person` {age: $q_Person_age, height: $q_Person_height})', q_Person_age: 41, q_Person_height: 70
    end
  end

  describe '#merge' do
    describe ".merge('(:Person)')" do
      it_generates 'MERGE (:Person)'
    end

    describe '.merge(:Person)' do
      it_generates 'MERGE (:Person)'
    end

    describe '.merge(:Person).merge(:Thing)' do
      it_generates 'MERGE (:Person) MERGE (:Thing)'
    end

    describe '.merge(age: 41, height: 70)' do
      it_generates 'MERGE ( {age: $age, height: $height})', age: 41, height: 70
    end

    describe '.merge(Person: {age: 41, height: 70})' do
      it_generates 'MERGE (:`Person` {age: $Person_age, height: $Person_height})', Person_age: 41, Person_height: 70
    end

    describe '.merge(q: {Person: {age: 41, height: 70}})' do
      it_generates 'MERGE (q:`Person` {age: $q_Person_age, height: $q_Person_height})', q_Person_age: 41, q_Person_height: 70
    end
  end


  # DELETE

  describe '#delete' do
    describe ".delete('n')" do
      it_generates 'DELETE n'
    end

    describe '.delete(:n)' do
      it_generates 'DELETE n'
    end

    describe ".delete('n', :o)" do
      it_generates 'DELETE n, o'
    end

    describe ".delete(['n', :o])" do
      it_generates 'DELETE n, o'
    end
  end

  # DETACH DELETE

  describe '#delete' do
    describe ".detach_delete('n')" do
      it_generates 'DETACH DELETE n'
    end

    describe '.detach_delete(:n)' do
      it_generates 'DETACH DELETE n'
    end

    describe ".detach_delete('n', :o)" do
      it_generates 'DETACH DELETE n, o'
    end

    describe ".detach_delete(['n', :o])" do
      it_generates 'DETACH DELETE n, o'
    end
  end

  # SET

  describe '#set_props' do
    describe ".set_props('n = {name: \"Brian\"}')" do
      it_generates 'SET n = {name: "Brian"}'
    end

    describe ".set_props(n: {name: 'Brian', age: 30})" do
      it_generates 'SET n = $n_set_props', n_set_props: {name: 'Brian', age: 30}
    end
  end

  describe '#set' do
    describe ".set('n = {name: \"Brian\"}')" do
      it_generates 'SET n = {name: "Brian"}'
    end

    describe ".set(n: {name: 'Brian', age: 30})" do
      it_generates 'SET n.`name` = $setter_n_name, n.`age` = $setter_n_age', setter_n_name: 'Brian', setter_n_age: 30
    end

    describe ".set(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates 'SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.`age` = $setter_o_age', setter_n_name: 'Brian', setter_n_age: 30, setter_o_age: 29
    end

    describe ".set(n: {name: 'Brian', age: 30}).set_props('o.age = 29')" do
      it_generates 'SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.age = 29', setter_n_name: 'Brian', setter_n_age: 30
    end

    describe '.set(n: :Label)' do
      it_generates 'SET n:`Label`'
    end

    describe ".set(n: [:Label, 'Foo'])" do
      it_generates 'SET n:`Label`, n:`Foo`'
    end

    describe '.set(n: nil)' do
      it_generates ''
    end
  end

  # ON CREATE and ON MATCH should behave just like set_props
  describe '#on_create_set' do
    describe ".on_create_set('n = {name: \"Brian\"}')" do
      it_generates 'ON CREATE SET n = {name: "Brian"}'
    end

    describe '.on_create_set(n: {})' do
      it_generates '', {}
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30})" do
      it_generates 'ON CREATE SET n.`name` = $setter_n_name, n.`age` = $setter_n_age', setter_n_name: 'Brian', setter_n_age: 30
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates 'ON CREATE SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.`age` = $setter_o_age',
                   setter_n_name: 'Brian', setter_n_age: 30, setter_o_age: 29
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30}).on_create_set('o.age = 29')" do
      it_generates 'ON CREATE SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.age = 29', setter_n_name: 'Brian', setter_n_age: 30
    end
  end

  describe '#on_match_set' do
    describe ".on_match_set('n = {name: \"Brian\"}')" do
      it_generates 'ON MATCH SET n = {name: "Brian"}'
    end

    describe '.on_match_set(n: {})' do
      it_generates '', {}
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30})" do
      it_generates 'ON MATCH SET n.`name` = $setter_n_name, n.`age` = $setter_n_age', setter_n_name: 'Brian', setter_n_age: 30
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates 'ON MATCH SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.`age` = $setter_o_age',
                   setter_n_name: 'Brian', setter_n_age: 30, setter_o_age: 29
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30}).on_match_set('o.age = 29')" do
      it_generates 'ON MATCH SET n.`name` = $setter_n_name, n.`age` = $setter_n_age, o.age = 29', setter_n_name: 'Brian', setter_n_age: 30
    end
  end

  # REMOVE

  describe '#remove' do
    describe ".remove('n.prop')" do
      it_generates 'REMOVE n.prop'
    end

    describe ".remove('n:American')" do
      it_generates 'REMOVE n:American'
    end

    describe ".remove(n: 'prop')" do
      it_generates 'REMOVE n.prop'
    end

    describe '.remove(n: :American)' do
      it_generates 'REMOVE n:`American`'
    end

    describe '.remove(n: [:American, "prop"])' do
      it_generates 'REMOVE n:`American`, n.prop'
    end

    describe ".remove(n: :American, o: 'prop')" do
      it_generates 'REMOVE n:`American`, o.prop'
    end

    describe ".remove(n: ':prop')" do
      it_generates 'REMOVE n:`prop`'
    end
  end

  # FOREACH


  # UNION

  describe '#union_cypher' do
    it 'returns a cypher string with the union of the callee and argument query strings' do
      q = Neo4j::Core::Query.new.match(o: :Person).where(o: {age: 10})
      result = Neo4j::Core::Query.new.match(n: :Person).union_cypher(q)

      expect(result).to eq('MATCH (n:`Person`) UNION MATCH (o:`Person`) WHERE (o.age = $o_age)')
    end

    it 'can represent UNION ALL with an option' do
      q = Neo4j::Core::Query.new.match(o: :Person).where(o: {age: 10})
      result = Neo4j::Core::Query.new.match(n: :Person).union_cypher(q, all: true)

      expect(result).to eq('MATCH (n:`Person`) UNION ALL MATCH (o:`Person`) WHERE (o.age = $o_age)')
    end
  end


  # START

  describe '#start' do
    describe ".start('r=node:nodes(name = \"Brian\")')" do
      it_generates 'START r=node:nodes(name = "Brian")'
    end

    describe ".start(r: 'node:nodes(name = \"Brian\")')" do
      it_generates 'START r = node:nodes(name = "Brian")'
    end
  end


  describe 'clause combinations' do
    describe ".match(q: Person).where('q.age > 30')" do
      it_generates 'MATCH (q:`Person`) WHERE (q.age > 30)'
    end

    describe ".where('q.age > 30').match(q: Person)" do
      it_generates 'MATCH (q:`Person`) WHERE (q.age > 30)'
    end

    describe ".where('q.age > 30').start('n').match(q: Person)" do
      it_generates 'START n MATCH (q:`Person`) WHERE (q.age > 30)'
    end

    describe '.match(q: {age: 30}).set_props(q: {age: 31})' do
      it_generates 'MATCH (q {age: $q_age}) SET q = $q_set_props', q_age: 30, q_set_props: {age: 31}
    end

    # WITHS

    describe ".match(q: Person).with('count(q) AS count')" do
      it_generates 'MATCH (q:`Person`) WITH count(q) AS count'
    end

    describe ".match(q: Person).with('count(q) AS count').where('count > 2')" do
      it_generates 'MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2)'
    end

    describe ".match(q: Person).with(count: 'count(q)').where('count > 2').with(new_count: 'count + 5')" do
      it_generates 'MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2) WITH count + 5 AS new_count'
    end

    # breaks

    describe ".match(q: Person).match('r:Car').break.match('(p: Person)-->q')" do
      it_generates 'MATCH (q:`Person`), r:Car MATCH (p: Person)-->q'
    end

    describe ".match(q: Person).break.match('r:Car').break.match('(p: Person)-->q')" do
      it_generates 'MATCH (q:`Person`) MATCH r:Car MATCH (p: Person)-->q'
    end

    describe ".match(q: Person).match('r:Car').break.break.match('(p: Person)-->q')" do
      it_generates 'MATCH (q:`Person`), r:Car MATCH (p: Person)-->q'
    end

    describe ".with(:a).order(a: {name: :desc}).where(a: {name: 'Foo'})" do
      it_generates 'WITH a ORDER BY a.name DESC WHERE (a.name = $a_name)', a_name: 'Foo'
    end

    describe ".with(:a).limit(2).where(a: {name: 'Foo'})" do
      it_generates 'WITH a LIMIT $limit_2 WHERE (a.name = $a_name)', a_name: 'Foo', limit_2: 2
    end

    describe ".with(:a).order(a: {name: :desc}).limit(2).where(a: {name: 'Foo'})" do
      it_generates 'WITH a ORDER BY a.name DESC LIMIT $limit_2 WHERE (a.name = $a_name)', a_name: 'Foo', limit_2: 2
    end

    describe ".order(a: {name: :desc}).with(:a).where(a: {name: 'Foo'})" do
      it_generates 'WITH a ORDER BY a.name DESC WHERE (a.name = $a_name)', a_name: 'Foo'
    end

    describe ".limit(2).with(:a).where(a: {name: 'Foo'})" do
      it_generates 'WITH a LIMIT $limit_2 WHERE (a.name = $a_name)', a_name: 'Foo', limit_2: 2
    end

    describe ".order(a: {name: :desc}).limit(2).with(:a).where(a: {name: 'Foo'})" do
      it_generates 'WITH a ORDER BY a.name DESC LIMIT $limit_2 WHERE (a.name = $a_name)', a_name: 'Foo', limit_2: 2
    end

    describe ".with('1 AS a').where(a: 1).limit(2)" do
      it_generates 'WITH 1 AS a WHERE (a = $a) LIMIT $limit_2', a: 1, limit_2: 2
    end

    # params
    describe ".match(q: Person).where('q.age = $age').params(age: 15)" do
      it_generates 'MATCH (q:`Person`) WHERE (q.age = $age)', age: 15
    end
  end

  describe 'merging queries' do
    let(:query1) { Neo4j::Core::Query.new.match(p: Person) }
    let(:query2) { Neo4j::Core::Query.new.match(c: :Car) }

    it 'Merging two matches' do
      expect((query1 & query2).to_cypher).to eq('MATCH (p:`Person`), (c:`Car`)')
    end

    it 'Makes a query that allows further querying' do
      expect((query1 & query2).match('(p)-[:DRIVES]->(c)').to_cypher).to eq('MATCH (p:`Person`), (c:`Car`), (p)-[:DRIVES]->(c)')
    end

    it 'merges params'

    it 'merges options'
  end
end
