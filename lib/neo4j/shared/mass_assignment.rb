module Neo4j::Shared
  # MassAssignment allows you to bulk set and update attributes
  #
  # Including MassAssignment into your model gives it a set of mass assignment
  # methods, similar to those found in ActiveRecord.
  #
  # @example Usage
  #   class Person
  #     include Neo4j::Shared::MassAssignment
  #   end
  #
  # Originally part of ActiveAttr, https://github.com/cgriego/active_attr
  module MassAssignment
    extend ActiveSupport::Concern
    # Mass update a model's attributes
    #
    # @example Assigning a hash
    #   person.assign_attributes(:first_name => "Chris", :last_name => "Griego")
    #   person.first_name #=> "Chris"
    #   person.last_name #=> "Griego"
    #
    # @param [Hash{#to_s => Object}, #each] attributes Attributes used to
    #   populate the model
    # @param [Hash, #[]] options Options that affect mass assignment
    def assign_attributes(new_attributes = nil)
      return unless new_attributes.present?
      new_attributes.each do |name, value|
        writer = :"#{name}="
        send(writer, value) if respond_to?(writer)
      end
    end

    # Mass update a model's attributes
    #
    # @example Assigning a hash
    #   person.attributes = { :first_name => "Chris", :last_name => "Griego" }
    #   person.first_name #=> "Chris"
    #   person.last_name #=> "Griego"
    #
    # @param (see #assign_attributes)
    def attributes=(new_attributes)
      assign_attributes(new_attributes)
    end

    # Initialize a model with a set of attributes
    #
    # @example Initializing with a hash
    #   person = Person.new(:first_name => "Chris", :last_name => "Griego")
    #   person.first_name #=> "Chris"
    #   person.last_name #=> "Griego"
    #
    # @param (see #assign_attributes)
    def initialize(attributes = nil)
      assign_attributes(attributes)
      super()
    end
  end
end
