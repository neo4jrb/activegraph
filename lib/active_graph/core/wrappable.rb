module ActiveGraph
  module Core
    module Wrappable
      extend ActiveSupport::Concern

      def wrap
        self.class.wrap(self)
      end

      class_methods do
        def wrapper_callback(proc)
          fail 'Callback already specified!' if @wrapper_callback
          @wrapper_callback = proc
        end

        def clear_wrapper_callback
          @wrapper_callback = nil
        end

        def wrap(node)
          if @wrapper_callback
            @wrapper_callback.call(node)
          else
            node
          end
        end
      end
    end
  end
end
