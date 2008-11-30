require 'logger'
$LUCENE_LOGGER = Logger.new(STDOUT)
$LUCENE_LOGGER.level = Logger::WARN

require 'lucene/index'
require 'lucene/transaction'
require 'lucene/index_searcher'
require 'lucene/hits'
require 'lucene/config'

