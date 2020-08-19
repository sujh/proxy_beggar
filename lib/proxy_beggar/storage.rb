require 'yaml'
require 'redis'
require_relative './config.rb'

class ProxyBeggar
  class Storage
    def initialize(opts = { url: Config[:storage][:path] })
      @entity = ::Redis.new(opts)
    end

    def store(v)
      if v.respond_to?(:to_a)
        if v.empty?
          p "Warning: skip store for empty set"
          return
        end
        @entity.sadd(Config[:storage][:key], v.to_a)
      else
        @entity.sadd(Config[:storage][:key], v.to_s)
      end
    end

    def get_all
      @entity.smembers(Config[:storage][:key])
    end

    def clean
      @entity.del(Config[:storage][:key])
    end

    def delete(v)
      @entity.srem(Config[:storage][:key], v)
    end
  end
end