require_relative './base_crawler'

class ProxyBeggar
  class Eight9ipCrawler < BaseCrawler
    def parse_proxies(doc)
      doc.css('table tbody tr').each do |node|
        children = node.css('td').map(&:text).map { |_t| _t.gsub(/\s/, '') }
        ip_pos, port_pos = 0, 1
        record_proxy(children[ip_pos], children[port_pos])
      end
      raw_proxies
    end

    def url(page = 1)
      "http://www.89ip.cn/index_#{page}.html"
    end
  end
end