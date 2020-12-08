module ActiveGraph
  module Transaction
    def failure
      super
      @failure = true
    end

    def close
      success
      super
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    def apply_callbacks
      after_commit_registry.each(&:call) unless @failure
    end

    private

    def after_commit_registry
      @after_commit_registry ||= []
    end
  end
end
