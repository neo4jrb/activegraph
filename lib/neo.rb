# 
# Set logger used by Neo
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$neo_logger = Logger.new(STDOUT)
$neo_logger.level = Logger::WARN
#$neo_logger.level = Logger::INFO


require 'neo/java_libs'
require 'neo/neo_service'
require 'neo/transaction'
require 'neo/node'


module Neo
 
  #
  # Returns a NeoService
  # 
  def neo_service
    NeoService.instance
  end  
  
  module_function :neo_service
end

