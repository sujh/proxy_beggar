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

    def run(page_limit: 10, request_gap_time: 2)
      (1..page_limit).each do |page|
        _url = url(page)
        if doc = fetch_doc(_url)
          parse_proxies doc
          p "#{self.class}: Success for #{_url}(proxy: #{requestor.proxy})"
          sleep request_gap_time
        else
          p "Get #{_url} failed(proxy: #{requestor.proxy}), next"
        end
      end
      raw_proxies
    end

    def fetch_doc(url, timeout = 5)
      retry_time = 2
      begin
        valid_proxy = @proxy_pool.pick
        doc = requestor.get(url, timeout, proxy: valid_proxy)
      rescue Timeout::Error => e
        return if valid_proxy.nil?
        @proxy_pool.delete(valid_proxy)
        p "#{valid_proxy} is expired, delete and switch"
        retry
      rescue StandardError => e
        if e.message.match?("redirection forbidden")
          # When this happen, it seems like this proxy can't visit crawler's url, but it can visit other site,
          # so soft delete it
          @proxy_pool.delete(valid_proxy, false)
          p "Redirection forbidden: proxy: #{valid_proxy}, url: #{url}, switch"
          retry
        else
          p "#{e}, proxy: #{valid_proxy}. Left retry times: #{retry_time}"
          retry_time -= 1
          if retry_time >= 0
            sleep 2
            retry
          else
            @proxy_pool.delete(valid_proxy)
            return nil
          end
        end
      end
      Nokogiri::HTML(doc)
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
