require 'timeout'
require 'open-uri'
require 'set'
require_relative './config'
class ProxyBeggar
  class Requestor

    attr_reader :options

    def initialize(opts = {})
      @options = opts.merge("User-Agent" => Config[:requestor][:user_agent], proxy: nil)
    end

    def get(url, time_limit = Config[:requestor][:time_limit], **opts)
      Timeout.timeout(time_limit) { URI.open(url, **options.merge!(**opts)) }
    end

    def test_proxy(proxy, url)
      begin
        !!get(url, proxy: proxy)
      rescue StandardError => e
        p "Proxy unavailable: proxy: #{proxy}, cause: #{e}"
        return false
      end
    end

    def proxy
      options[:proxy]
    end

  end
end