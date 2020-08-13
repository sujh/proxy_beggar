class ProxyBeggar
  class Proxy
    attr_reader :scheme, :ip, :port
    def initialize(scheme, ip, port)
      @scheme = scheme.downcase
      @ip = ip
      @port = port
    end

    def to_s
      #Open-uri can't work with non-http proxy
      "http://#{ip}:#{port}"
    end

  end
end