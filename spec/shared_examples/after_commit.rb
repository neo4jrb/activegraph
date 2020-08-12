shared_context 'after_commit' do |company_variable, options|
  before(:each) do
    %w(update create destroy).each do |verb|
      Company.send(:attr_reader, :"after_#{verb}_commit_called")
    end

    Company.after_create_commit { @after_create_commit_called = true }
    Company.after_update_commit { @after_update_commit_called = true }
    Company.after_destroy_commit { @after_destroy_commit_called = true }
  end

  let(:company) { send(company_variable) }
  let(:transactions_count) { options[:transactions_count] }
  let(:fail_transaction) { options[:fail_transaction] }

  let(:to_or_not_to) { options[:fail_transaction] ? :not_to : :to }

  def wrap_in_transactions(count, &block)
    ActiveGraph::Base.transaction(&count == 1 ? block : ->(tx) { wrap_in_transactions(count - 1, &block) })
  end

  it "handles after_create_commit callbacks #{options.inspect}" do
    company = Company.new

    if transactions_count.zero?
      expect { company.save }.to change do
        company.after_create_commit_called
      end
    else
      expect do
        wrap_in_transactions(transactions_count) do |tx|
          company.save
          tx.rollback if fail_transaction
        end
      end.send(to_or_not_to, change { company.after_create_commit_called })
    end
  end

  it 'handles after_update_commit callbacks' do
    company
    if transactions_count.zero?
      expect { company.update(name: 'some') }.to change do
        company.after_update_commit_called
      end
    else
      expect do
        wrap_in_transactions(transactions_count) do |tx|
          company.update(name: 'some')
          tx.rollback if fail_transaction
        end
      end.send(to_or_not_to, change { company.after_update_commit_called })
    end
  end

  it 'handles after_destroy_commit callbacks' do
    company
    if transactions_count.zero?
      expect { company.destroy }.to change do
        company.after_destroy_commit_called
      end
    else
      expect do
        wrap_in_transactions(transactions_count) do |tx|
          company.destroy
          tx.rollback if fail_transaction
        end
      end.send(to_or_not_to, change { company.after_destroy_commit_called })
    end
  end
end
