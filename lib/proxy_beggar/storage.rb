require 'yaml'
require 'redis'
require 'json'
require_relative './config.rb'

class ProxyBeggar
  class Storage
    def initialize(opts = { url: Config[:storage][:path] })
      @entity = ::Redis.new(opts)
    end

    def store(v)
      @entity.sadd(Config[:storage][:key], v)
    end

    def get_all
      @entity.smembers(Config[:storage][:key])
    end
  end
end