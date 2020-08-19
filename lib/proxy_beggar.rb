require 'set'
require_relative './proxy_beggar/valid_proxy_pool'
require_relative './proxy_beggar/config'

class ProxyBeggar

  def initialize
    @pool = ValidProxyPool.instance
  end

  def beg(crawlers: load_crawlers, target: Config[:requestor][:default_target])
    proxies = Set.new
    Array(crawlers).each_with_object([]) do |crawler, threads|
      threads << Thread.new do
        proxies.merge crawler.run
      end
    end.each(&:join)
    @pool.refresh_valid_proxies(proxies, target)
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