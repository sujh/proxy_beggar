require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require_relative '../lib/proxy_beggar/proxy_manager'

describe ProxyBeggar::ProxyManager do
  before :each do
    @manager = ProxyBeggar::ProxyManager.instance
    @manager.instance_variable_set("@storage", ProxyBeggar::Storage.new(url: "redis://127.0.0.1:6379/2"))
    @manager.valid_proxies.clear
  end

  after :each do
    @manager.valid_proxies.clear
  end

  describe "#instance" do
    it "return singleton object" do
      assert_equal @manager, ProxyBeggar::ProxyManager.instance
    end
  end

  describe "#refresh_valid_proxies" do
    it "valid_proxies is empty when all candidate proxies can't work " do
      invalid_proxies = [Object.new, Object.new]
      @manager.requestor.stub :test_proxy, false do
        @manager.refresh_valid_proxies(invalid_proxies)
      end
      assert_empty @manager.valid_proxies
    end

    it "works ok when input proxies is empty" do
      @manager.refresh_valid_proxies([])
      assert_empty @manager.valid_proxies
    end

    it "works when some candidate proxies ok " do
      proxies = ['proxy_dummy1', 'proxy_dummy2']
      @manager.requestor.stub :test_proxy, true do
        @manager.refresh_valid_proxies(proxies)
      end
      assert_equal @manager.valid_proxies.size, proxies.size
    end
  end

  describe "#pick" do
    it "works" do
      proxies = %w(http://1.1.1.1:1 http://1.2.2.2:2)
      proxies.each { |pxy| @manager.valid_proxies << pxy }
      assert_includes proxies, @manager.pick
    end

    it "works when valid proxies is empty" do
      @manager.valid_proxies.clear
      assert_nil @manager.pick
    end
  end

  describe "#delete" do
    it "delete ele from manager and storage" do
      @manager.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      @manager.send(:save_valid_proxies)
      ori_size = @manager.valid_proxies.size
      real_size = @manager.delete("http://1.1.1.1:1", true).size
      assert_equal ori_size - 1, real_size

      storage_size = @manager.instance_variable_get("@storage").get_all.size
      assert_equal ori_size - 1, storage_size
    end

    it "delete ele form only manager when soft delete " do
      @manager.valid_proxies << "http://1.1.1.1:1" << "http://1.2.2.2:2"
      @manager.send(:save_valid_proxies)
      ori_size = @manager.valid_proxies.size
      real_size = @manager.delete("http://1.1.1.1:1", false).size
      assert_equal ori_size - 1, real_size

      storage_size = @manager.instance_variable_get("@storage").get_all.size
      assert_equal ori_size, storage_size
    end
  end
end
