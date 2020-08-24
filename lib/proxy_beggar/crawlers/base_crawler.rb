require 'nokogiri'
require 'timeout'
require_relative '../valid_proxy_pool'

class ProxyBeggar
  class BaseCrawler
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'

    attr_reader :raw_proxies, :requestor

    def initialize
      @raw_proxies = []
      @requestor   = Requestor.new
      @proxy_pool  = ValidProxyPool.instance
    end

    def run(page_limit: 10)
      (1..page_limit).each do |page|
        _url = url(page)
        if doc = fetch_doc(_url)
          parse_proxies doc
          p "Success for #{_url}(proxy: #{requestor.proxy})"
          @proxy_pool.refresh_valid_proxies(raw_proxies)
          @proxy_pool.save_valid_proxies
          raw_proxies.clear
        else
          p "Get #{_url} failed(proxy: #{requestor.proxy}), next"
        end
      end
    end

    def fetch_doc(url, timeout = 5)
      begin
        valid_proxy = @proxy_pool.pick
        doc = requestor.get(url, timeout, proxy: valid_proxy)
        return Nokogiri::HTML(doc)
      rescue Timeout::Error => e
        return if valid_proxy.nil?
        @proxy_pool.delete(valid_proxy)
        p "#{valid_proxy} is expired, soft delete and switch"
        retry
      rescue StandardError => e
        @proxy_pool.delete(valid_proxy)
        p "#{e}, proxy: #{valid_proxy}, url: #{url}" and retry
      end
    end

    def url(page = 1)
      raise "Abstract method, should be implemented in subclass"
    end

    def parse_proxies(doc)
      raise "Abstract method, should be implemented in subclass"
    end

    private

      def record_proxy(ip, port, scheme = 'http')
        #Open-uri can't work with non-http proxy
        raw_proxies << "http://#{ip}:#{port}"
      end

  end
end
