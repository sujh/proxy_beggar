require 'rack'
require 'json'
require_relative 'storage'

class ProxyBeggar
  class App
    attr_reader :data_source

    def initialize
      @data_source = Storage.new
    end

    def call(env)
      status = 200
      headers = {'Content-Type' => 'application/json'}
      request = Rack::Request.new(env)
      proxies = data_source.get_all
      if request.params["pretty"]
        data = JSON.pretty_generate proxies
      else
        data = proxies.to_json
      end
      [status, headers, [data]]
    end
  end
end
