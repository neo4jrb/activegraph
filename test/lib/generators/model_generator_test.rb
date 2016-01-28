# require 'test_helper'
require File.expand_path('../../../test_helper', __FILE__)
require 'rails/generators/neo4j/model/model_generator.rb'

class Neo4j::Generators::ModelGeneratorTest < Rails::Generators::TestCase
  destination File.join(Rails.root)
  tests Neo4j::Generators::ModelGenerator

  setup :prepare_destination
  setup :copy_routes

  test 'invoke with model name' do
    run_generator %w(Account)

    assert_file 'app/models/account.rb' do |account|
      assert_class 'Account', account do |klass|
        assert_equal 'include Neo4j::ActiveNode', klass
      end
    end
  end

  test 'invoke with model name using namespace' do
    run_generator %w(Namespaces Account)

    assert_file 'app/models/namespaces/account.rb' do |account|
      assert_class 'Namespaces::Account', account do |klass|
        assert_equal 'include Neo4j::ActiveNode', klass
      end
    end
  end

  test 'invoke with model name and attributes' do
    run_generator %w(Account name:string age:integer)

    assert_file 'app/models/account.rb' do |account|
      assert_class 'Account', account do |klass|
        assert_match(/property :name/, klass)
        assert_match(/property :age, :type => Integer/, klass)
      end
    end
  end

  test 'attribute types' do
    assert_equal 'Date', create_generated_attribute(:date).type_class
    assert_equal 'Integer', create_generated_attribute(:integer).type_class
    assert_equal 'Integer', create_generated_attribute(:number).type_class
    assert_equal 'Integer', create_generated_attribute(:Integer).type_class
    assert_equal 'DateTime', create_generated_attribute(:datetime).type_class
    assert_equal 'String', create_generated_attribute(:string).type_class
    assert_equal 'String', create_generated_attribute(:no_exist).type_class
  end

  test 'invoke with model name and --timestamps option' do
    run_generator %w(Account --timestamps)

    assert_file 'app/models/account.rb' do |account|
      assert_class 'Account', account do |klass|
        assert_match(/property :created_at/, klass)
        assert_match(/property :updated_at/, klass)
      end
    end
  end

  # test "invoke with model name and --parent option" do
  #   content = run_generator %w(Admin --parent User)
  #   assert_file "app/models/admin.rb" do |account|
  #     puts "ACCOUNT #{account}"
  #     assert_class "Admin", account do |klass|
  #       assert_match /<\s+User/, klass
  #     end
  #   end
  # end
end
