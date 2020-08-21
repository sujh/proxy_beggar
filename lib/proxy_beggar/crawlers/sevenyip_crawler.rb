require_relative './base_crawler'

class ProxyBeggar
  class SevenyipCrawler < BaseCrawler

    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        tds = node.css('td')
        ip = tds[0].text.strip
        port = tds[1].text.strip
        proto = tds[3].text.downcase.strip
        record_proxy(ip, port, proto)
      end
    end

    def url(page = 1)
      "https://www.7yip.cn/free/?page=#{page}"
    end

  end
end
