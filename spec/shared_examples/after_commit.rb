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

  let(:transactions) { Array.new(transactions_count) { ActiveGraph::Base.new_transaction } }
  let(:close_inner_transactions!) { transactions.reverse.first(transactions_count - 1).each(&:close) }
  let(:to_or_not_to) { options[:fail_transaction] ? :not_to : :to }

  it 'handles after_create_commit callbacks' do
    company = Company.new

    if transactions.empty?
      expect { company.save }.to change do
        company.after_create_commit_called
      end
    else
      company.save
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { company.after_create_commit_called })
    end
  end

  it 'handles after_update_commit callbacks' do
    company
    if transactions.empty?
      expect { company.update(name: 'some') }.to change do
        company.after_update_commit_called
      end
    else
      company.update(name: 'some')
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { company.after_update_commit_called })
    end
  end

  it 'handles after_destroy_commit callbacks' do
    company
    if transactions.empty?
      expect { company.destroy }.to change do
        company.after_destroy_commit_called
      end
    else
      company.destroy
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { company.after_destroy_commit_called })
    end
  end
end
