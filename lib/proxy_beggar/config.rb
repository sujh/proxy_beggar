require 'yaml'

class ProxyBeggar
  class Config
    class HashWithIndifferentAccess
      def initialize(hash)
        @hash = hash
      end

      def [](k)
        rst = @hash[k.to_s]
        if rst.is_a? Hash
          self.class.new rst
        else
          rst
        end
      end

      def []=(k, v)
        @hash[k.to_s] = v
      end

      def method_missing(m, *args, &blk)
        @hash.send(m, *args, &blk)
      end
    end

    @entity ||= HashWithIndifferentAccess.new YAML.load_file(File.expand_path('../../../data/config.yml', __FILE__))

    class << self
      def method_missing(m, *args, &blk)
        @entity.send(m, *args, &blk)
      end
    end

  end
end