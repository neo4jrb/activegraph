require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Model, "lint", :type => :transactional do
  %w{to_model to_key to_param valid? persisted?}.each do |m|
    it { should respond_to m }
  end

  its(:to_model)  { should == subject }
  it              { should be_valid }
  it              { should_not be_persisted }
  its(:class)     { should respond_to(:model_name) }

  #TODO: Consider this as many gems reflect on it
  #its(:column_names)  { should respond_to(:model_name) }

  describe ".model_name" do
    subject             { Neo4j::Model.model_name }

    it                  { should be_kind_of String }
    its(:human)         { should be_kind_of(String) }
    its(:singular)      { should be_kind_of(String) }
    its(:plural)        { should be_kind_of(String) }
  end

  context "when not persisted" do
    def subject
      super.errors
    end

    it { should respond_to(:[]) }
    it { should respond_to(:full_messages) }
    it { should respond_to(:add) }

    it "accessing error should give an array" do
      subject[:email].should be_an_instance_of Array
    end

    its(:full_messages) { should be_an_instance_of Array }

    context "accessing error" do
      def subject
        super[:email]
      end

      it { should be_an_instance_of Array }
      it { should be_an_instance_of Array }
    end
  end
  
end


