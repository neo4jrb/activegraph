require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'active_support/core_ext/exception'

describe Neo4j::Rails::Compositions do
  context "for single value object" do
    it "should create a object composed of single value" do
      customer = Customer.create!(:balance => 50)

      customer.balance.amount.should == 50
      customer.balance.should be_a(Money)
      customer.balance.exchange_to("DKK").amount.should == 300
    end
  end

  context "for multiple value object" do
    it "should create a object composed of multiple values" do
      customer = Customer.create!(:address_street => "Funny Street", :address_city => "Scary Town",
                                  :address_country => "Loony Land")

      customer.address.should be_a(Address)
      customer.address.street.should == customer.address_street
      customer.address.city.should == customer.address_city
      customer.address.country.should == customer.address_country
      customer.address.should be_close_to(Address.new("Different Street", customer.address_city, customer.address_country))
    end
  end

  it "should persist change in composed object" do
    customer = Customer.create!(:balance => 50)
    customer.balance = Money.new(100)

    customer.save

    customer.reload.balance.amount.should == 100
  end

  it "should create immutable composite objects" do
    customer = Customer.create!(:balance => 50)

    expect {
     customer.balance.instance_eval { @amount = 20 }
    }.to raise_error(ActiveSupport::FrozenObjectError)
  end

  it "should infer mapping from composition name" do
    customer = Customer.create!
    customer[:gps_location] = "35.544623640962634x-105.9309951055148"

    customer.gps_location.latitude.should == "35.544623640962634"
    customer.gps_location.longitude.should == "-105.9309951055148"

    customer.gps_location = GpsLocation.new("39x-110")

    customer.gps_location.latitude.should == "39"
    customer.gps_location.longitude.should == "-110"

    customer.save

    customer.reload

    customer.gps_location.latitude.should == "39"
    customer.gps_location.longitude.should == "-110"
  end

  it "should refresh compositions on reload" do
    customer = Customer.create!(:balance => 50)
    customer.balance.amount.should == 50

    customer[:balance] = 100
    customer.save!

    customer.reload
    customer[:balance].should == 100
    customer.balance.amount.should == 100
  end

  context "when :allow_nil => true" do
    it "should allow creating object with nil values for composition" do
      Customer.create!(:gps_location => nil).gps_location.should be_nil
    end

    it "should allow set nil value for compositions" do
      customer = Customer.create!(:gps_location => GpsLocation.new("39x-110"))

      customer.gps_location = nil
      customer.save

      customer.reload
      customer.gps_location.should be_nil
    end

    describe "setting nil on composition" do
      let(:customer) { Customer.create!(:address_street => "Funny Street",
                                  :address_city => "Scary Town", :address_country => "Loony Land")}

      it "should set attributes to nil" do
        customer.address = nil

        customer.attributes[:address_street].should be_nil
        customer.attributes[:address_city].should be_nil
        customer.attributes[:address_country].should be_nil
      end

      it "should set and persist the composition as nil" do
        customer.address = nil
        customer.save

        customer.reload
        customer.address.should be_nil
      end
    end

    it "should load composite object when only some attributes are nil" do
      customer = Customer.create!(:address_street => "Funny Street",
                                  :address_city => "Scary Town", :address_country => "Loony Land")

      customer.address_street = nil
      customer.save

      customer.reload
      customer.address.should be_a(Address)
      customer.address.street.should be_nil
    end

    describe "setting nil on attribute" do
      it "should set composition to nil" do
        customer = Customer.create!(:gps_location => GpsLocation.new('39x111'))
        customer.gps_location.should_not be_nil

        customer[:gps_location] = nil
        customer.save!

        customer.reload.gps_location.should be_nil
      end
    end
  end

  context "when :allow_nil => false" do
    it "should delegate the conversion to the converter" do
      customer = Customer.create!(:balance => nil)

      customer.balance.should_not be_nil
      customer.balance.should be_a(Money)
      customer.balance.amount.should be_nil
    end
  end

  describe ":constructor => custom_constructor" do
    it "should be used for creating composite object" do
      customer = Customer.create!(:name => "Barney Gumble")

      customer.fullname.to_s.should == 'Barney GUMBLE'
      customer.fullname.should be_a(Fullname)
    end
  end

  describe ":converter => custom_converter" do
    it "should be used while setting composite object" do
      customer = Customer.create!(:name => "Barney Gumble")

      customer.fullname = 'Barnoit Gumbleau'

      customer.fullname.to_s.should == 'Barnoit GUMBLEAU'
      customer.fullname.should be_a(Fullname)
    end
  end
end