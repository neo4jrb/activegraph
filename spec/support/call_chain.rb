class CallChain
  def self.print(msg=nil, depth = 10)
    puts msg if msg
    (1..depth).each do |depth|
      p = parse_caller(caller(depth+2).first)
      puts "  #{depth} - #{p[0]}:#{p[1]} - #{p[2]}"
    end
  end

  def self.caller_method(depth=1)
    parse_caller(caller(depth+1).first).last
  end

  private

  #Stolen from ActionMailer, where this was used but was not made reusable
  def self.parse_caller(at)
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      [file, line, method]
    end
  end
end
