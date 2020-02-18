require 'spec_helper'
require 'active_graph/core/has_uri'

describe ActiveGraph::Core::HasUri do
  let(:uri_validation) {}
  let(:default_url) {}
  let!(:adaptor) do
    scoped_default_url = default_url
    scoped_uri_validation = uri_validation
    Class.new do
      include ActiveGraph::Core::HasUri
      default_url(scoped_default_url) if scoped_default_url
      validate_uri(&scoped_uri_validation)

      def initialize(url)
        self.url = url
      end
    end
  end

  subject { adaptor.new(url) }

  let_context default_url: 'foo://bar:baz@biz:1234' do
    let_context url: nil do
      its(:scheme) { should eq('foo') }
      its(:user) { should eq('bar') }
      its(:password) { should eq('baz') }
      its(:host) { should eq('biz') }
      its(:port) { should eq(1234) }
      its(:url_without_password) { should eq('foo://bar:...@biz:1234') }
    end

    let_context url: 'http://localhost:4321' do
      its(:scheme) { should eq('http') }
      its(:user) { should eq('bar') }
      its(:password) { should eq('baz') }
      its(:host) { should eq('localhost') }
      its(:port) { should eq(4321) }
      its(:url_without_password) { should eq('http://bar:...@localhost:4321') }
    end
  end

  let_context default_url: nil do
    let_context url: nil do
      subject_should_raise ArgumentError, /No URL or default URL/
    end

    let_context url: 'http://localhost:7474' do
      its(:scheme) { should eq('http') }
      its(:user) { should be_nil }
      its(:password) { should be_nil }
      its(:host) { should eq('localhost') }
      its(:port) { should eq(7474) }
      its(:url_without_password) { should eq('http://localhost:7474') }
    end
  end

  let_context uri_validation: ->(uri) { uri.port == 3344 } do
    let_context url: 'http://localhost:7474' do
      subject_should_raise ArgumentError, /Invalid URL/
    end
    let_context url: 'http://localhost:3344' do
      subject_should_not_raise
    end
  end
end
