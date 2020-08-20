require 'timeout'
require 'open-uri'
require 'set'
require_relative './config'
class ProxyBeggar
  class Requestor
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'

    attr_reader :options

    def initialize(opts = {})
      @options = opts.merge("User-Agent" => USER_AGENT, proxy: nil)
    end

    def get(url, timeout = 5, **opts)
      Timeout.timeout(timeout) { URI.open(url, **options.merge!(**opts)) }
    end

    def test_proxy(proxy, url)
      begin
        get(url, proxy: proxy)
      rescue StandardError => e
        p "Proxy unavailable: proxy: #{proxy}, url: #{url}, cause: #{e}"
        return false
      end
      true
    end

    def proxy
      options[:proxy]
    end

  end
end