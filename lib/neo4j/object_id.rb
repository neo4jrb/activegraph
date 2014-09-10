module Neo4j
  module ObjectId
    @@mutex = Mutex.new
    @@counter = 0

    def object_id
      require 'digest'
      require 'socket'

      @@mutex.lock
      begin
        count = @@counter = (@@counter + 1) % 0xFFFFFF
      ensure
        @@mutex.unlock rescue nil
      end
      machine_id = Digest::MD5.digest(Socket.gethostname).unpack("N")[0]
      process_id = RUBY_ENGINE == 'jruby' ? "#{Process.pid}#{Thread.current.object_id}".hash % 0xFFFF : Process.pid % 0xFFFF
      [ Time.now.to_i, machine_id, process_id, count << 8 ].pack("N NX lXX NX").unpack("H*")[0]
    end
  end
end
