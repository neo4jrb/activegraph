# frozen_string_literal: true

module ActiveGraph
  module SecureRandomExt
    def hex(n = nil)
      super.force_encoding(Encoding::UTF_8)
    end

    def uuid
      super.force_encoding(Encoding::UTF_8)
    end
  end
end
