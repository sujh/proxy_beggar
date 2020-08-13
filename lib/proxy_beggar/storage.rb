require 'yaml'
require 'redis'
require 'json'
require_relative './config.rb'

class ProxyBeggar
  class Storage
    def initialize(opts = { url: Config[:storage][:path] })
      @entity = ::Redis.new(opts)
    end

    def store(k, v)
      @entity.hset(Config[:storage][:key], k, v)
    end

    def get(k)
      @entity.hget(Config[:storage][:key], k)
    end

    def get_all
      @entity.hgetall(Config[:storage][:key])
    end
  end
end