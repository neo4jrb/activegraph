module Neo4j
  module Rails
    module HaConsole
      module Zookeeper
        class << self
          def shutdown
            return unless pid_file?
            file = File.open(pid_file, "rb")
            pid = file.read.to_s.chomp
            IO.popen("pkill -TERM -P #{pid}")
            puts "Zookeeper: shutdown #{pid}"
            system("rm -f #{pid_file}")
          end

          def clean
            dir = File.expand_path("data/zookeeper1/version-2", File.dirname(__FILE__))
            puts "Zookeeper: clean #{dir}"
            system("rm -rf #{dir}")
          end

          def pid_file
            File.expand_path("zookeeper.pid", File.dirname(__FILE__)).to_s
          end

          def pid_file?
            x = File.exist?(pid_file)
            puts "Zookeeper: pid file #{x} at #{pid_file}"
            x
          end

          def lib_dir
            File.expand_path("lib", File.dirname(__FILE__))
          end

          def copy_jars
            puts "Zookeeper: Copy JARs"
            files = $CLASSPATH.find_all{|x| x =~ /\.jar$/}.collect{|y| y.sub('file:', '')}
            zookeeper = files.find{|f| f =~ /\/zookeeper/}
            raise "zookeper JAR not found in a GEM, did you forget to include neo4j-enterprise in your Gemfile (development)" unless zookeeper

            log4j = files.find{|f| f =~ /\/log4j/}
            raise "log4j not found in a GEM, did you forget to include neo4j-enterprise in your Gemfile (development)" unless log4j


            system("mkdir -p #{lib_dir}")
            FileUtils.cp(zookeeper, lib_dir)
            FileUtils.cp(log4j, lib_dir)
          end

          def start
            puts "Zookeeper: start, check jars?"
            copy_jars unless File.exist?(lib_dir)
            zookeeper_exec = File.expand_path("start_zookeeper.sh", File.dirname(__FILE__)).to_s
            Dir.chdir(File.dirname(__FILE__))
            pipe = IO.popen(zookeeper_exec)
            File.open(pid_file, 'w') { |f| f.write(pipe.pid) }
          end
        end
      end
    end
  end
end
