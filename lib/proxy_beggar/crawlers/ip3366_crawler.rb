require_relative './base_crawler'

class ProxyBeggar
  class Ip3366Crawler < BaseCrawler

    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        tds = node.css('td')
        ip = tds[0].text
        port = tds[1].text
        proto = tds[3].text
        record_proxy(ip, port, proto)
      end
    end

    def url(page = 1)
      "http://www.ip3366.net/?stype=1&page=#{page}"
    end

  end
end
