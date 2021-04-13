require 'set'
require 'thread/pool'
require_relative './client'
require_relative './config'
require_relative './storage'

class ProxyBeggar
  # Some proxies can't visit crawler's url, but can visit normal site. These proxies will be deleted from
  # valid_proxies, but will remain in storage. Crawlers should use ProxyManager's proxies instead of storage's.

  class ProxyManager
    attr_reader :client, :valid_proxies
    private_class_method :new

    def self.instance(client: Client.new)
      @manager ||= new(client)
    end

    def initialize(client)
      @client = client
      @storage = Storage.new
      @valid_proxies = persisted_proxies
      @refresher_pool = Thread.pool(Config[:manager][:refresher_threads])
      @clearer_pool = Thread.pool(Config[:manager][:clearer_threads])
    end

    def refresh_valid_proxies(proxies, target = Config[:client][:target])
      return if proxies.empty?
      proxies.each do |proxy|
        @refresher_pool.process do
          if client.test_proxy(proxy, target)
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

    def hard_clear_invalid_proxies(target = Config[:client][:target])
      proxies = persisted_proxies
      return if proxies.empty?
      proxies.each do |proxy|
        @clearer_pool.process do
          unless client.test_proxy(proxy, target)
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