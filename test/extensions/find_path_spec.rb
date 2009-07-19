$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'neo4j/extensions/find_path'

class Currency
  include Neo4j::NodeMixin
  property :code
end

class ExchangeRate
  include Neo4j::NodeMixin
  property :rate
  has_one :from_currency
  has_one :to_currency
end


describe "NodeTraverser#path_to" do
  before(:all) do
    start
  end

  before(:each) do
    Neo4j::Transaction.new
    @gbp = Currency.new; @gbp.code = 'GBP'
    @usd = Currency.new; @usd.code = 'USD'
    @eur = Currency.new; @eur.code = 'EUR'
    @jpy = Currency.new; @jpy.code = 'JPY'
    @chf = Currency.new; @chf.code = 'CHF'
    @eur_gbp = ExchangeRate.new; @eur_gbp.from_currency = @eur; @eur_gbp.to_currency = @gbp; @eur_gbp.rate = 0.86320
    @gbp_usd = ExchangeRate.new; @gbp_usd.from_currency = @gbp; @gbp_usd.to_currency = @usd; @gbp_usd.rate = 1.6381
    @usd_eur = ExchangeRate.new; @usd_eur.from_currency = @usd; @usd_eur.to_currency = @eur; @usd_eur.rate = 0.70721
    @jpy_usd = ExchangeRate.new; @jpy_usd.from_currency = @jpy; @jpy_usd.to_currency = @usd; @jpy_usd.rate = 0.010608
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  def currency_path(path)
    return nil if path.nil?

    path.each_index do |i|
      path[i] = case path[i]
        when Currency
          path[i].code
        when ExchangeRate
          (path[i].from_currency == path[i+1]) ? 1.0/path[i].rate : path[i].rate
      end
    end
  end

  it "should return nil if there is no path" do
    @gbp.traverse.both(:from_currency, :to_currency).depth(:all).path_to(@chf).should be_nil
  end

  it "should return [] if the two nodes are the same" do
    @usd.traverse.both(:from_currency, :to_currency).depth(:all).path_to(@usd).should == []
  end

  it "should find a single outgoing link" do
    path = @eur_gbp.traverse.both(:from_currency, :to_currency).depth(:all).path_to(@gbp)
    currency_path(path).should == [0.86320, 'GBP']
  end

  it "should find a single incoming link" do
    path = @usd.traverse.both(:from_currency, :to_currency).depth(:all).path_to(@usd_eur)
    currency_path(path).should == ['USD', 0.70721]
  end

  it "should find the shorter path if there are alternatives" do
    path = @jpy.traverse.both(:from_currency, :to_currency).depth(:all).path_to(@eur)
    currency_path(path).should == ['JPY', 0.010608, 'USD', 0.70721, 'EUR']
  end

  it "should respect traversal constraints" do
    path = @eur.traverse.incoming(:to_currency).outgoing(:from_currency).depth(:all).path_to(@gbp)
    currency_path(path).should == ['EUR', 1/0.70721, 'USD', 1/1.6381, 'GBP']
  end
end
