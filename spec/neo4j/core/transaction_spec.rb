require 'spec_helper'
require 'neo4j/transaction'

describe Neo4j::Transaction do
  describe '.session_and_run_in_tx_from_args' do
    let(:session_double) do
      class_double(Neo4j::Core::CypherSession).tap do |double|
        allow(double).to receive(:is_a?).with(Class) { true }
      end
    end

    subject do
      final_args = args.map { |a| a == :session_double ? session_double : a }
      Neo4j::Transaction.session_and_run_in_tx_from_args(final_args)
    end

    let_context(args: []) { subject_should_raise ArgumentError, 'Too few arguments' }

    let_context(args: [true]) { subject_should_raise ArgumentError, 'Session must be specified' }
    let_context(args: [false]) { subject_should_raise ArgumentError, 'Session must be specified' }
    let_context(args: ['something else']) { subject_should_raise ArgumentError, 'Session must be specified' }

    let_context(args: [:session_double]) { it { should eq([session_double, true]) } }

    # This method doesn't care what you pass as the non-boolean value
    # so using a symbol here
    let_context(args: [:session_double]) { it { should eq([session_double, true]) } }

    let_context(args: [false, :session_double]) { it { should eq([session_double, false]) } }
    let_context(args: [true, :session_double]) { it { should eq([session_double, true]) } }

    let_context(args: [:session_double, false]) { it { should eq([session_double, false]) } }
    let_context(args: [:session_double, true]) { it { should eq([session_double, true]) } }

    let_context(args: [:session_double, true, :foo]) { subject_should_raise ArgumentError, /Too many arguments/ }
  end
end
