describe Neo4j::Paginated do
  describe 'initialize' do
    it 'sets instance variables @items, @total, @current_page' do
      a = Neo4j::Paginated.new(5, 10, 15)
      %w(@items @total @current_page).each { |i| expect(a.instance_variable_defined?(i.to_sym)).to be_truthy }
    end
  end
end
