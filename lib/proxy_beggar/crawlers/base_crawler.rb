require 'nokogiri'
require 'timeout'
require 'set'
require_relative '../proxy'
require_relative '../valid_proxy_pool'

class ProxyBeggar
  class BaseCrawler
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'

    attr_reader :raw_proxies, :requestor

    def initialize
      @raw_proxies = Set.new
      @requestor   = Requestor.new
      @proxy_pool  = ValidProxyPool.instance
    end

    def run(page_limit: 10, request_gap_time: 2)
      (1..page_limit).each do |page|
        _url = url(page)
        if doc = fetch_doc(_url)
          parse_proxies doc
          p "#{self.class}: Success for #{_url}(proxy: #{requestor.proxy})"
          sleep request_gap_time
        else
          p "Get #{_url} expired(proxy: #{requestor.proxy}), next"
        end
      end
      raw_proxies
    end

    def fetch_doc(url, timeout = 5)
      begin
        valid_proxy = @proxy_pool.pick
        doc = requestor.get(url, timeout, proxy: valid_proxy)
      rescue Timeout::Error => e
        return if valid_proxy.nil?
        @proxy_pool.delete(valid_proxy)
        p "#{valid_proxy} is invalid, switch"
        retry
      rescue StandardError => e
        raise(e, "#{e} when visit #{url}")
      end
      Nokogiri::HTML(doc)
    end

    def url(page = 1)
      raise "Abstract method, should be implemented in subclass"
    end

    def parse_proxies(doc)
      raise "Abstract method, should be implemented in subclass"
    end

  end
end
