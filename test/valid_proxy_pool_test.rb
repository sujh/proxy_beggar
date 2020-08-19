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
    it "return empty set when no valid proxies" do
      invalid_proxies = %w(http://1.1.1.1:10 http://2.2.2.2:10)
      assert_empty @pool.refresh_valid_proxies(invalid_proxies)
    end

    it "works ok when input proxies is empty" do
      assert_empty @pool.refresh_valid_proxies([])
    end
  end

  describe "#pick" do
    it "works" do
      expected_value = "http://1.1.1.1:1"
      @pool.valid_proxies << expected_value << "http://1.2.2.2:2"
      assert_equal expected_value, @pool.pick
    end

    it "works when valid proxies is empty" do
      @pool.valid_proxies.clear
      assert_nil @pool.pick
    end
  end

  describe "#delete" do
    it "delete ele from pool" do
      @pool.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      ori_size = @pool.valid_proxies.size
      assert_equal ori_size - 1, @pool.delete("http://1.1.1.1:1").size
    end

    it "delete ele form storage" do
      @pool.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      @pool.send(:refresh_to_storage)
      ori_size = @pool.instance_variable_get("@storage").get_all.size
      assert_equal ori_size - 1, @pool.delete("http://1.1.1.1:1").size
    end
  end
end