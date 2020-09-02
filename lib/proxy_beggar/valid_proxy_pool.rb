require 'set'
require_relative './requestor'
require_relative './config'
require_relative './storage'

class ProxyBeggar
  # Some proxies can't visit crawler's url, but can visit normal site. These proxies will be deleted form
  # valid_proxies, but will remain in storage. Crawlers should use ValidProxyPool's proxies instead of storage's.

  class ValidProxyPool
    attr_reader :requestor, :valid_proxies
    private_class_method :new

    def self.instance(requestor: Requestor.new)
      @pool ||= new(requestor)
    end

    def initialize(requestor)
      @requestor = requestor
      @storage = Storage.new
      @valid_proxies = persisted_proxies
    end

    def refresh_valid_proxies(proxies, target = Config[:requestor][:target])
      return if proxies.empty?
      thread_limit = Config[:thread_limit].to_f
      proxies.each_slice((proxies.size / thread_limit).ceil).with_object([]) do |part_proxies, threads|
        threads << Thread.new do
          part_proxies.each do |proxy|
            if requestor.test_proxy(proxy, target)
              p "Proxy ok: proxy: #{proxy}, url: #{target}"
              valid_proxies << proxy
            end
          end
        end
      end.each(&:join)
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
      thread_limit = 5.0
      proxies.each_slice((proxies.size / thread_limit).ceil).with_object([]) do |part_proxies, threads|
        threads << Thread.new do
          part_proxies.each do |proxy|
            unless requestor.test_proxy(proxy, target)
              p "Persisted proxy is obsoleted: proxy: #{proxy}, url: #{target}"
              delete(proxy, true)
            end
          end
        end
      end.each(&:join)
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