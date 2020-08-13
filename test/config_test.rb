require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require_relative '../lib/proxy_beggar/config'

describe ProxyBeggar::Config do
  before :each do
    @yml = YAML.load_file(File.expand_path('../../data/config.yml', __FILE__))
  end

  describe "#[]" do
    it "get value with different key type" do
      assert_equal ProxyBeggar::Config[:storage][:path], @yml['storage']['path']
      assert_equal ProxyBeggar::Config['storage']['path'], @yml['storage']['path']
    end
  end
end
