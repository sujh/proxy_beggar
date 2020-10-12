require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require_relative '../lib/proxy_beggar/valid_proxy_pool'

describe ProxyBeggar::ValidProxyPool do
  before :each do
    @pool = ProxyBeggar::ValidProxyPool.instance
    @pool.instance_variable_set("@storage", ProxyBeggar::Storage.new(url: "redis://127.0.0.1:6379/2"))
    @pool.valid_proxies.clear
  end

  after :each do
    @pool.valid_proxies.clear
  end

  describe "#instance" do
    it "return singleton object" do
      assert_equal @pool, ProxyBeggar::ValidProxyPool.instance
    end
  end

  describe "#refresh_valid_proxies" do
    it "valid_proxies is empty when all candidate proxies can't work " do
      invalid_proxies = [Object.new, Object.new]
      @pool.requestor.stub :test_proxy, false do
        @pool.refresh_valid_proxies(invalid_proxies)
      end
      assert_empty @pool.valid_proxies
    end

    it "works ok when input proxies is empty" do
      @pool.refresh_valid_proxies([])
      assert_empty @pool.valid_proxies
    end

    it "works when some candidate proxies ok " do
      proxies = ['proxy_dummy1', 'proxy_dummy2']
      @pool.requestor.stub :test_proxy, true do
        @pool.refresh_valid_proxies(proxies)
      end
      assert_equal @pool.valid_proxies.size, proxies.size
    end
  end

  describe "#pick" do
    it "works" do
      proxies = %w(http://1.1.1.1:1 http://1.2.2.2:2)
      proxies.each { |pxy| @pool.valid_proxies << pxy }
      assert_includes proxies, @pool.pick
    end

    it "works when valid proxies is empty" do
      @pool.valid_proxies.clear
      assert_nil @pool.pick
    end
  end

  describe "#delete" do
    it "delete ele from pool and storage" do
      @pool.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      @pool.send(:save_valid_proxies)
      ori_size = @pool.valid_proxies.size
      real_size = @pool.delete("http://1.1.1.1:1", true).size
      assert_equal ori_size - 1, real_size

      storage_size = @pool.instance_variable_get("@storage").get_all.size
      assert_equal ori_size - 1, storage_size
    end

    it "delete ele form only pool when soft delete " do
      @pool.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      @pool.send(:save_valid_proxies)
      ori_size = @pool.valid_proxies.size
      real_size = @pool.delete("http://1.1.1.1:1", false).size
      assert_equal ori_size - 1, real_size

      storage_size = @pool.instance_variable_get("@storage").get_all.size
      assert_equal ori_size, storage_size
    end
  end
end
