require_relative './proxy_beggar/proxy_manager'
require_relative './proxy_beggar/config'

class ProxyBeggar

  def beg(crawlers = ProxyBeggar.load_crawlers)
    Thread.new do
      manager = ProxyManager.instance
      loop do
        sleep Config[:beggar][:clean_gap_time]
        manager.hard_clear_invalid_proxies
      end
    end

    Array(crawlers).each_with_object([]) do |crawler, threads|
      threads << Thread.new do
        loop do
          crawler.run
          sleep Config[:beggar][:crawl_gap_time]
        end
      end
    end.each(&:join)
  end

  def self.load_crawlers
    Dir['./proxy_beggar/crawlers/*.rb', base: __dir__].each_with_object([]) do |path, objs|
      unless path.match?('base_crawler')
        require_relative path
        file_name = path.match(/(\w+)\.rb/)[1]
        klass = self.const_get(file_name.split('_').map(&:capitalize).join(''))
        objs << klass.new
      end
    end
  end

end
# require_relative './proxy_beggar/crawlers/sevenyip_crawler'
# ProxyBeggar.new.beg(ProxyBeggar::SevenyipCrawler.new)
# ProxyBeggar.new.beg