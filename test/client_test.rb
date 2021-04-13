require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require 'webmock/minitest'
require_relative '../lib/proxy_beggar/client'

describe ProxyBeggar::Client do

  before :each do
    @client = ProxyBeggar::Client.new
  end

  describe '#get' do
    it 'raise time error when request time out' do
      dummy_url = 'http://1.1.1.1:1'
      stub_request(:any, dummy_url).to_timeout
      assert_raises Timeout::Error do
        @client.get(dummy_url)
      end
    end

    it 'works' do
      dummy_url = 'http://1.1.1.1:1'
      stub_request(:get, dummy_url)
      assert @client.get(dummy_url)
    end
  end

  describe "#test_proxy" do
    it 'return false and print message when visit url failed via proxy' do
      dummy_proxy = 'http://1.1.1.1:1'
      dummy_url = 'http://2.2.2.2:2'
      stub_request(:get, dummy_url).to_timeout
      assert_equal false, @client.test_proxy(dummy_proxy, dummy_url)
      assert_output /proxy/ do
        @client.test_proxy(dummy_proxy, dummy_url)
      end
    end

    it 'return true when visit url success via proxy' do
      dummy_proxy = 'http://1.1.1.1:1'
      dummy_url = 'http://2.2.2.2:2'
      stub_request(:get, dummy_url)
      assert @client.test_proxy(dummy_proxy, dummy_url)
    end
  end

end