Dir["#{File.dirname(__FILE__)}/*/*.rake"].each { |f| load f }
#require File.join(File.dirname(__FILE__), "upgrade_v2", "upgrade_v2")