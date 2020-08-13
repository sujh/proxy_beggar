require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require 'json'
require_relative '../lib/proxy_beggar/storage'

describe ProxyBeggar::Storage do
  before :each do
    @storage = ProxyBeggar::Storage.new(url: "redis://127.0.0.1:6379/2")
    @store_entity = @storage.instance_variable_get('@entity')
  end

  after :each do
    @store_entity.del(ProxyBeggar::Config[:storage][:key])
  end

  describe "#store" do
    it "works" do
      proxy = { ip: '1.1.1.1' }
      @storage.store('1.1.1.1', JSON.dump(proxy))
      assert_equal 1, @store_entity.hlen(ProxyBeggar::Config[:storage][:key])
    end
  end

  describe "#get" do
    it "works" do
      proxy = { ip: '1.1.1.2', port: '2' }
      @storage.store('1.1.1.2', JSON.dump(proxy))
      persisted_proxy = JSON.load @storage.get(proxy[:ip])
      assert_equal proxy[:ip], persisted_proxy['ip']
      assert_equal proxy[:port], persisted_proxy['port']
    end
  end

  describe "#get_all" do
    it 'works' do
      @storage.store('key1', 'v1')
      @storage.store('key2', 'v2')
      assert_equal({"key1"=>"v1", "key2"=>"v2"}, @storage.get_all)
    end
  end
end

