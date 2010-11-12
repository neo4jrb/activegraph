module Neo4j
	module Rails
		module Finders
			extend ActiveSupport::Concern
			
			included do
				rule :_all
			end
			
			module ClassMethods
				# overwrite the index method to add find_by_xxx class methods
				def index(*args)
					field = args.first
					module_eval <<-RUBY, __FILE__, __LINE__
						def self.all_by_#{field}(value)
							find_with_indexer("#{field}: \\"\#{value}\\"")
						end
						
						def self.find_by_#{field}(value)
							all_by_#{field}(value).first
						end
					RUBY
					
					super
				end
				
				# load an id or array of ids from the database
				def load(*ids)
          result = ids.map { |id| Neo4j::Node.load(id) }
          if ids.length == 1
            result.first
          else
            result
          end
        end
        
				# Behave like the ActiveRecord query interface
				
				# Handle Model.find(params[:id])
				
				# Model.find
				# Model.find(:first)
				
				# Model.find("1")
				# Model.find(1)
				
				# Model.find("name: test")
				# Model.find(:name => "test")
				
				# Model.find(:first, "name: test")
				# Model.find(:first, { :name => "test" })
				
				# Model.find(:first, :conditions => "name: test")
				# Model.find(:first, :conditions => { :name => "test" })
				
				# Model.find(:all, "name: test")
				# Model.find(:all, { :name => "test" })
				
				# Model.find(:all, :conditions => "name: test")
				# Model.find(:all, :conditions => { :name => "test" })
        def find(*args)
        	case args.first
        	when :all, :first
        		kind = args.shift
        		send(kind, *args)
        	else
        		find_with_ids(*args) or first(*args)
        	end
        end
        
				def all(*args)
					if args.empty?
						# use the _all rule to recover all the stored instances of this node
						_all
					else
						args = normalize_args(*args)
						# handle the special case of a search by id
						if args.first.is_a?(Hash) && args.first[:id]
							[find_with_ids(args.first[:id])].flatten
						else
							find_with_indexer(*args)
						end
					end
				end
				
				def first(*args)
					all(*args).first
				end
				
				def last(*args)
					a = all(*args)
					a.empty? ? nil : a[a.size - 1]
				end
				
				protected
				def find_with_ids(*args)
					if ((args.first.is_a?(String) || args.first.is_a?(Integer)) && args.first.to_i > 0)
						load(*args.map { |p| p.to_i })
					end
				end
				
				def find_with_indexer(*args)
					hits = _indexer.find(*args)
					# We need to save this so that the Rack Neo4j::Rails:LuceneConnection::Closer can close it
					Thread.current[:neo4j_lucene_connection] ||= []
					Thread.current[:neo4j_lucene_connection] << hits
					hits
				end
				
				def normalize_args(*args)
					options = args.extract_options!
					
					if options.present?
						if options[:conditions]
							args << options[:conditions]
						else
							args << options
						end
					end
					args
				end
      end
		end
	end
end

