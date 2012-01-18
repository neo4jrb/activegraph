require 'rubygems'
require "bundler/setup"
require 'fileutils'
require 'tmpdir'

require 'neo4j'
require '../v2_0_0'
require 'domain'

#$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'neo4j'
require 'logger'
Neo4j::Config[:logger_level] = Logger::ERROR
Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "old_neo_db")
Neo4j::Config[:debug_java] = true
Neo4j::Config[:identity_map] = false
Neo4j::IdentityMap.enabled = false

include Neo4j::Upgrade::V2_0_0

def rm_db_storage
  FileUtils.rm_rf Neo4j::Config[:storage_path]
  raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
end

rm_db_storage


puts "$NEO4J_CLASSES: #{$NEO4J_CLASSES.inspect}"

def create_data(domain_name=nil)
  puts "CREATE DATA #{domain_name} <<<<<<<<<<<<<<<<<"
  domain1 = nil
  if domain_name
    domain1 = Domain.create!(:name => domain_name)
    Neo4j.threadlocal_ref_node=domain1
  else
    Neo4j.threadlocal_ref_node=Neo4j.default_ref_node
    domain_name = "Root"
  end


  proj1 = Project.create!(:name => 'proj1', :domain => domain_name)
  proj2 = Project.create!(:name => 'proj2', :domain => domain_name)

  person1 = Person.create!(:name => 'person1', :domain => domain_name)
  person2 = Person.create!(:name => 'person2', :domain => domain_name)
  proj1.people << person1 << person2
  proj1.save!

  proj2.people << person2
  proj2.save!
  domain1
end

def verify(domain=nil)
  Neo4j.threadlocal_ref_node= (domain || Neo4j.default_ref_node)
  proj1 = Project.find_by_name('proj1')
  proj2 = Project.find_by_name('proj2')
  puts "Domain #{domain && domain.name}"
  puts "  Person#people  1 size: #{proj1.people.size} = #{proj1._java_node.outgoing('Person#people').size}  (#{proj1.domain})"
  puts "  Person#people  2 size: #{proj2.people.size} = #{proj2._java_node.outgoing('Person#people').size}  (#{proj2.domain})"
  puts "  Project#people 1 size: #{proj1.people.size} = #{proj1._java_node.outgoing('Project#people').size} (#{proj1.domain})"
  puts "  Project#people 2 size: #{proj2.people.size} = #{proj2._java_node.outgoing('Project#people').size} (#{proj1.domain})"
  puts "  TOTAL Person #{Person.all.size}, Projects #{Project.all.size}"
end

domain1 = create_data("domain1")
domain2 = create_data("domain2")
create_data(nil)

verify
verify(domain1)
verify(domain2)

migrate_all!(Domain.all.to_a + [Neo4j.default_ref_node])

puts "============================="
verify
verify(domain1)
verify(domain2)
