require_relative './proxy_beggar/valid_proxy_pool'
require_relative './proxy_beggar/config'

class ProxyBeggar

  def beg(crawlers = load_crawlers)
    Thread.new do
      pool = ValidProxyPool.instance
      loop do
        sleep Config[:begger][:clean_gap_time]
        pool.hard_clear_invalid_proxies
      end
    end

    Array(crawlers).each_with_object([]) do |crawler, threads|
      threads << Thread.new do
        loop do
          crawler.run
          sleep Config[:begger][:crawl_gap_time]
        end
      end
    end.each(&:join)
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
#require_relative './proxy_beggar/crawlers/sevenyip_crawler'
#ProxyBeggar.new.beg(ProxyBeggar::SevenyipCrawler.new)
ProxyBeggar.new.beg