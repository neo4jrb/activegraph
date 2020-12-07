module ActiveGraph
  module Transaction
    def failure
      super
      @failure = true
    end

    def close
      return if @closed
      @closed = true

      success
      super
      after_commit_registry.each(&:call) unless @failure
    end

    def after_commit(&block)
      after_commit_registry << block
    end

    private

    def after_commit_registry
      @after_commit_registry ||= []
    end
  end
end
