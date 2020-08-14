require 'set'
require_relative './proxy_beggar/storage'
require_relative './proxy_beggar/requestor'
require_relative './proxy_beggar/config'

class ProxyBeggar
  THREAD_LIMIT = Config[:beggar][:thread_limit].to_f
  attr_reader :requestor

  def initialize
    @storage = Storage.new
    @requestor = Requestor.new
  end

  def beg(crawlers: load_crawlers, target: Config[:beggar][:default_target])
    proxies = Set.new
    #persisted_proxies = select_valid_persisted_proxies(target)
    Array(crawlers).each_with_object([]) do |crawler, threads|
      threads << Thread.new do
        proxies.merge crawler.run
      end
    end.each(&:join)
    @storage.store(select_valid_proxies(proxies, target))
  end

  def pick_proxy_for(url)
    @proxies_for_crawler ||= select_valid_persisted_proxies(url)
    @proxies_for_crawler.shift
  end

  def select_valid_persisted_proxies(target = Config[:beggar][:default_target])
    select_valid_proxies(@storage.get_all)
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

  def select_valid_proxies(proxies, target = Config[:beggar][:default_target])
    threads = []
    valid_proxies = Set.new
    proxies.each_slice((proxies.size / THREAD_LIMIT).ceil) do |part_proxies|
      threads << Thread.new do
        part_proxies.each do |proxy|
          if proxy_available?(proxy, target)
            p "Proxy is available: proxy: #{proxy}, url: #{target}"
            valid_proxies << proxy
          else
            next
          end
        end
      end
    end
    threads.each(&:join)
    valid_proxies
  end

  private

    def load_crawlers
      Dir['./proxy_beggar/crawlers/*.rb'].each_with_object([]) do |path, objs|
        unless path.match?('base_crawler')
          require_relative path
          file_name = path.match(/(\w+)\.rb/)[1]
          klass = self.class.const_get(file_name.split('_').map(&:capitalize).join(''))
          objs << klass.new
        end
      end
    end

end

ProxyBeggar.new.beg