class Animal < Neo4j::RailsNode
  property :name
end

class Human < Animal
end

class AnimalObserver < Neo4j::Rails::Observer
  attr_reader :last_after_create_record

  def after_create(record)
    @last_after_create_record = record
  end
end

class CallbackRecorder < Neo4j::Rails::Observer
  observe :animal

  attr_reader :last_callback, :call_count, :last_record

  def initialize
    reset
    super
  end

  def reset
    @last_callback = nil
    @call_count = Hash.new(0)
    @last_record = {}
  end

  Neo4j::Rails::Callbacks::CALLBACKS.each do |callback|
    define_method(callback) do |record, &block|
      @last_callback = callback
      @call_count[callback] += 1
      @last_record[callback] = record
      block ? block.call : true
    end
  end
end

