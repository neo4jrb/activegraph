module ActiveGraph
  module Transaction
    def rollback
      @active_graph_rolled_back = true
    end

    def check_rollback
      fail ActiveGraph::Rollback if @active_graph_rolled_back
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    def apply_callbacks
      after_commit_registry.each(&:call)
    end

    private

    def after_commit_registry
      @after_commit_registry ||= []
    end
  end
end
