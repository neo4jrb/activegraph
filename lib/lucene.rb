require 'logger'
$LUCENE_LOGGER = Logger.new(STDOUT)
$LUCENE_LOGGER.level = Logger::WARN

require 'lucene/config'
require 'lucene/document'
require 'lucene/field_info'
require 'lucene/hits'
require 'lucene/index'
require 'lucene/index_info'
require 'lucene/index_searcher'
require 'lucene/jars'
require 'lucene/query_dsl'
require 'lucene/transaction'

