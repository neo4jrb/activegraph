module ActiveGraph
  module Transaction
    def rollback
      super
      @rolled_back = true
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    def apply_callbacks
      after_commit_registry.each(&:call) unless @rolled_back
    end

    private

    def after_commit_registry
      @after_commit_registry ||= []
    end
  end
end
