require 'rspec'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "impl")

require 'rspec-apigen'

# load the stuff we are specifying the API to
require 'account'
require 'transfer_dsl'

