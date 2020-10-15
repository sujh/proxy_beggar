require 'nokogiri'
require 'timeout'
require_relative '../proxy_manager'
require_relative '../config'

class ProxyBeggar
  class BaseCrawler

    attr_reader :raw_proxies, :requestor

    def initialize
      @raw_proxies = []
      @requestor   = Requestor.new
      @manager  = ProxyManager.instance
    end

    def run(page_limit = self.page_limit)
      (1..page_limit).each do |page|
        _url = url(page)
        if doc = fetch_doc(_url)
          parse_proxies doc
          p "Success for #{_url}(proxy: #{requestor.proxy})"
          @manager.refresh_valid_proxies(raw_proxies)
          @manager.save_valid_proxies
          raw_proxies.clear
        else
          p "Get #{_url} failed(proxy: #{requestor.proxy}), next"
        end
      end
    end

    def fetch_doc(url, time_limit = self.time_limit)
      begin
        valid_proxy = @manager.pick
        doc = requestor.get(url, time_limit, proxy: valid_proxy)
        return Nokogiri::HTML(doc)
      rescue Timeout::Error => e
        return if valid_proxy.nil?
        @manager.delete(valid_proxy)
        p "#{valid_proxy} is expired, soft delete and switch"
        retry
      rescue StandardError => e
        @manager.delete(valid_proxy)
        p "#{e}, proxy: #{valid_proxy}, url: #{url}" and retry
      end
    end

    def url(page = 1)
      raise "Abstract method, should be implemented in subclass"
    end

    def parse_proxies(doc)
      raise "Abstract method, should be implemented in subclass"
    end

    def page_limit
      crawler_config(:page_limit) || 10
    end

    def time_limit
      crawler_config(:time_limit) || 5
    end

    private

      def record_proxy(ip, port, scheme = 'http')
        #Open-uri can't work with non-http proxy
        raw_proxies << "http://#{ip}:#{port}"
      end

      def crawler_config(key)
        @crawler_config ||= Config.dig('crawlers', self.class.to_s.split('::')[-1])
        @crawler_config&.[](key.to_s)
      end

  end
end
