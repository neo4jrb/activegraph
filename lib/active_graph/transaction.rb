module ActiveGraph
  module Transaction
    def rollback
      fail ActiveGraph::Rollback
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    def apply_callbacks
      after_commit_registry.each(&:call)
    end

    def clear_callbacks
      after_commit_registry.clear
    end

    private

    def after_commit_registry
      @after_commit_registry ||= []
    end
  end
end
