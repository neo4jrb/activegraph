require 'shared_examples/new_model'
require 'shared_examples/loadable_model'
require 'shared_examples/saveable_model'
require 'shared_examples/creatable_model'
require 'shared_examples/destroyable_model'

describe 'BasicModel' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('BasicModel') do
      property :name
      property :a
      property :b

      before_destroy :before_destroy_callback
      def before_destroy_callback
        self.class.before_destroy_callback_calls += 1
      end

      class << self
        attr_accessor :before_destroy_callback_calls
      end

      self.before_destroy_callback_calls = 0
    end
  end

  subject { BasicModel.new }

  it_should_behave_like 'new model'
  it_should_behave_like 'loadable model'
  it_should_behave_like 'saveable model'
  it_should_behave_like 'creatable model'
  it_should_behave_like 'destroyable model'
  it_should_behave_like 'updatable model'

  it 'has a label' do
    expect(subject.class.create!.labels).to eq([:BasicModel])
  end

  context "when there's lots of them" do
    before(:each) do
      subject.class.delete_all
      3.times { subject.class.create! }
    end

    it 'should be possible to #count' do
      expect(subject.class.count).to eq(3)
    end

    it 'should be possible to #delete_all' do
      expect_any_instance_of(subject.class).not_to receive(:before_destroy_callback)

      expect(subject.class.count).to eq 3
      expect(subject.class.before_destroy_callback_calls).to eq 0
      subject.class.delete_all
      expect(subject.class.count).to eq 0
      expect(subject.class.before_destroy_callback_calls).to eq 0
    end

    it 'should be possible to #destroy_all' do
      expect(subject.class.count).to eq 3
      expect(subject.class.before_destroy_callback_calls).to eq 0
      subject.class.destroy_all
      expect(subject.class.count).to eq 0
      expect(subject.class.before_destroy_callback_calls).to eq 3
    end
  end
end
