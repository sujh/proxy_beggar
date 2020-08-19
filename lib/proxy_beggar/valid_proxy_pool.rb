require 'set'
require_relative './requestor'
require_relative './config'
require_relative './storage'

class ProxyBeggar
  class ValidProxyPool
    attr_reader :requestor, :valid_proxies
    private_class_method :new

    def self.instance(requestor: Requestor.new)
      @pool ||= new(requestor)
    end

    def initialize(requestor)
      @requestor = requestor
      @storage = Storage.new
      @valid_proxies = @storage.get_all.to_set
    end

    def refresh_valid_proxies(proxies, target = Config[:requestor][:default_target])
      return valid_proxies if proxies.empty?
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
      refresh_to_storage
      valid_proxies
    end

    def pick
      valid_proxies.first
    end

    def delete(proxy, hard_delete = true)
      @storage.delete(proxy) if hard_delete
      valid_proxies.delete(proxy)
    end

    private

      def refresh_to_storage
        @storage.clean
        @storage.store(valid_proxies)
      end

  end
end