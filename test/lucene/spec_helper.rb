require 'fileutils'

include Lucene

def setup_lucene
  # make sure any previous transaction has commited
  Lucene::Transaction.current.commit if Lucene::Transaction.running?
  Lucene::Config.delete_all
  Lucene::Config[:store_on_file] = false
end
