require_relative './base_crawler'

class ProxyBeggar
  class Eight9ipCrawler < BaseCrawler
    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        tds = node.css('td')
        ip = tds[0].text.strip
        port = tds[1].text.strip
        record_proxy(ip, port)
      end
    end

    def url(page = 1)
      "http://www.89ip.cn/index_#{page}.html"
    end
  end
end