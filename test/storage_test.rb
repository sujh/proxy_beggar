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
      @storage.store('1.1.1.1')
      assert_equal 1, @store_entity.scard(ProxyBeggar::Config[:storage][:key])
    end
  end

  describe "#get_all" do
    it 'works' do
      @storage.store('v1')
      @storage.store('v2')
      @storage.store('v2')
      assert_equal(%w(v1 v2).sort, @storage.get_all.sort)
    end
  end
end

