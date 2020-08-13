require 'timeout'
require 'open-uri'
require_relative './proxy_beggar/storage'
require_relative './proxy_beggar/requestor'

class ProxyBeggar
  #autoload(:Config, './proxy_beggar/config.rb')
  attr_reader :requestor

  def initialize(dest_addr)
    @dest_addr = dest_addr
    @storage = Storage.new
    @requestor = Requestor.new
  end

  def beg
    load_crawlers.each do |crawler|
      beg_to crawler.new
    end
  end

  def beg_to(crawler)
    threads = []
    #crawler.requestor.proxy = pick_proxy_for(crawler.url)
    crawler.run.each_slice(5) do |_proxies|
      threads << Thread.new do
        _proxies.each do |proxy|
          if proxy_available?(proxy.to_s, @dest_addr)
            p "Proxy is available: proxy: #{proxy}, url: #{@dest_addr}"
            @storage.store(proxy.to_s)
          else
            next
          end
        end
      end
    end
    threads.each(&:join)
  end

  def pick_proxy_for(url)
    @proxies_for_crawler ||= filter_persisted_proxies_by(url)
    @proxies_for_crawler.shift
  end

  def filter_persisted_proxies_by(url)
    threads = []
    rst = []
    @storage.get_all.values.each_slice(2) do |proxies|
      threads << Thread.new do
        valid_proxies = proxies.each_with_object([]) do |proxy, obj|
          if proxy_available?(proxy, url)
            p "Proxy is available: proxy: #{proxy}, url: #{url}"
            obj << proxy
          end
        end
        Thread.current[:proxy] = valid_proxies
      end
    end

    threads.each do |t|
      t.join
      rst << t[:proxy] if t[:proxy]
    end
    rst.flatten
  end

  def proxy_available?(proxy, url)
    begin
      requestor.get(url, proxy: proxy)
    rescue StandardError => e
      p "Detect proxy failed: url: #{url}, proxy: #{proxy}, error: #{e}"
      return false
    end
    true
  end

  private

    def load_crawlers
      klasses = []
      Dir['./proxy_beggar/crawlers/*.rb'].each do |path|
        unless path.match?('base_crawler')
          require_relative path
          file_name = path.match(/(\w+)\.rb/)[1]
          klass = self.class.const_get(file_name.split('_').map(&:capitalize).join(''))
          klasses << klass
        end
      end
      klasses
    end

end

ProxyBeggar.new("https://www.baidu.com").beg