module ActiveGraph
  module SecureRandom
    def hex(n = nil)
      super.force_encoding(Encoding::UTF_8)
    end

    def uuid
      super.force_encoding(Encoding::UTF_8)
    end
  end
end
