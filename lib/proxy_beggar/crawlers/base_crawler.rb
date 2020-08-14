require 'nokogiri'
require 'timeout'
require 'set'
require_relative '../proxy'

class ProxyBeggar
  class BaseCrawler
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'

    attr_reader :proxies, :requestor

    def initialize
      @proxies = Set.new
      @requestor = Requestor.new
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
      proxies
    end

    def fetch_doc(url, timeout = 5)
      retry_count = 0
      begin
        doc = requestor.get(url, timeout)
      rescue Timeout::Error => e
        retry_count += 1
        timeout += 3
        retry_count < 3 ? retry : (return nil)
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
