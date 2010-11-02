module Neo4j
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
      
      source_root File.dirname(__FILE__) + '/templates'
      
      def model
        template "model.rb", File.join('app/models', "#{singular_name}.rb")
      end
      
      def controller
        template "controller.rb", File.join('app/controllers', "#{plural_name}_controller.rb")
      end
      
      def views
        empty_directory File.join('app/views', plural_name)
        template "view_index.html.erb", File.join('app/views', plural_name, "index.html.erb")
        template "view_show.html.erb", File.join('app/views', plural_name, "show.html.erb")
        template "view_new.html.erb", File.join('app/views', plural_name, "new.html.erb")
        template "view_edit.html.erb", File.join('app/views', plural_name, "edit.html.erb")
      end
      
      def tests
        template "controller_spec.rb", File.join('spec/controllers', "#{plural_name}_controller_spec.rb")
        template "model_spec.rb", File.join('spec/models', "#{singular_name}_model_spec.rb")
      end
      
      def add_route
        route "resources :#{plural_name}"
      end
    end
  end
end
