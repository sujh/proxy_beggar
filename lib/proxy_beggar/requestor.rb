require 'timeout'
require 'open-uri'
class ProxyBeggar
  class Requestor
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'

    attr_accessor :proxy
    attr_reader :options

    def initialize(opts = {})
      @proxy = nil
      @options = opts.merge("User-Agent" => USER_AGENT)
    end

    def get(url, timeout = 5, **opts)
      Timeout.timeout(timeout) { URI.open(url, **options.merge(proxy: @proxy, **opts)) }
    end

  end
end