require_relative './base_crawler'

class ProxyBeggar
  class XiladailiCrawler < BaseCrawler

    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        tds = node.css('td')
        ip, port = tds[0].text.split(':')
        proto = tds[1].text.scan(/\w+/).include?('HTTP') ? 'http' : 'https'
        record_proxy(ip, port, proto)
      end
      raw_proxies
    end

    def url(page = 1)
      "http://www.xiladaili.com/gaoni/#{page}/"
    end

  end
end
