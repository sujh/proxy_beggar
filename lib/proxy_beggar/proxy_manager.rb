require 'set'
require 'thread/pool'
require_relative './requestor'
require_relative './config'
require_relative './storage'

class ProxyBeggar
  # Some proxies can't visit crawler's url, but can visit normal site. These proxies will be deleted form
  # valid_proxies, but will remain in storage. Crawlers should use ProxyManager's proxies instead of storage's.

  class ProxyManager
    attr_reader :requestor, :valid_proxies
    private_class_method :new

    def self.instance(requestor: Requestor.new)
      @manager ||= new(requestor)
    end

    def initialize(requestor)
      @requestor = requestor
      @storage = Storage.new
      @valid_proxies = persisted_proxies
      @refresher_pool = Thread.pool(Config[:manager][:refresher_threads])
      @clearer_pool = Thread.pool(Config[:manager][:clearer_threads])
    end

    def refresh_valid_proxies(proxies, target = Config[:requestor][:target])
      return if proxies.empty?
      proxies.each do |proxy|
        @refresher_pool.process do
          if requestor.test_proxy(proxy, target)
            p "Proxy ok: proxy: #{proxy}"
            valid_proxies << proxy
          end
        end
      end
      @refresher_pool.wait(:done)
    end

    def pick
      valid_proxies.to_a.sample
    end

    def delete(proxy, hard_delete = false)
      @storage.delete(proxy) if hard_delete
      valid_proxies.delete(proxy)
    end

    def hard_clear_invalid_proxies(target = Config[:requestor][:target])
      proxies = persisted_proxies
      return if proxies.empty?
      proxies.each do |proxy|
        @clearer_pool.process do
          unless requestor.test_proxy(proxy, target)
            p "Persisted proxy is obsoleted: proxy: #{proxy}"
            delete(proxy, true)
          end
        end
      end
      @clearer_pool.wait(:done)
    end

    def save_valid_proxies
      @storage.store(valid_proxies)
    end

    private

      def persisted_proxies
        @storage.get_all.to_set
      end

  end
end