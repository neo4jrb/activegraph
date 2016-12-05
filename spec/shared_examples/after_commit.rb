shared_context 'after_commit' do |options|
  let(:transactions_count) { options[:transactions_count] }
  let(:fail_transaction) { options[:fail_transaction] }

  let(:transactions) { Array.new(transactions_count) { Neo4j::ActiveBase.new_transaction } }
  let(:close_inner_transactions!) { transactions.reverse.first(transactions_count - 1).each(&:close) }
  let(:to_or_not_to) { options[:fail_transaction] ? :not_to : :to }

  it 'handles after_create_commit callbacks' do
    company = Company.new

    if transactions.empty?
      expect { company.save }.to change { c.after_create_commit_called }
    else
      company.save
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { c.after_create_commit_called })
    end
  end

  it 'handles after_update_commit callbacks' do
    c
    if transactions.empty?
      expect { c.update(name: 'some') }.to change { c.after_update_commit_called }
    else
      c.update(name: 'some')
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { c.after_update_commit_called })
    end
  end

  it 'handles after_destroy_commit callbacks' do
    c
    if transactions.empty?
      expect { c.destroy }.to change { c.after_destroy_commit_called }
    else
      c.destroy
      transactions.last.mark_failed if fail_transaction
      close_inner_transactions!
      expect { transactions.first.close }.send(to_or_not_to, change { c.after_destroy_commit_called })
    end
  end
end
