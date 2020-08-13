require_relative './base_crawler'

class ProxyBeggar
  class Ip3366Crawler < BaseCrawler

    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        children = node.css('td').map(&:text)
        ip_pos, port_pos, proto_pos = 0, 1, 3
        proxies << Proxy.new(children[proto_pos], children[ip_pos], children[port_pos])
      end
      proxies
    end

    def url(page = 1)
      "http://www.ip3366.net/?stype=1&page=#{page}"
    end

  end
end
