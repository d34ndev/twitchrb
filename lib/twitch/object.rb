require "ostruct"

module Twitch
  class Object < OpenStruct
    def initialize(attributes)
      super to_ostruct(attributes)
    end

    def to_ostruct(obj)
      if obj.is_a?(Hash)
        OpenStruct.new(obj.map { |key, val| [ key, to_ostruct(val) ] }.to_h)
      elsif obj.is_a?(Array)
        obj.map { |o| to_ostruct(o) }
      else # Assumed to be a primitive value
        obj
      end
    end

    # Unlike OpenStruct#to_h, converts nested objects back into hashes too,
    # so the result can be serialized
    def to_h(&block)
      hash = super(&nil).transform_values { |value| to_hash_value(value) }
      block ? hash.to_h(&block) : hash
    end

    def as_json(*)
      to_h
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def to_hash_value(value)
      case value
      when OpenStruct
        value.to_h.transform_values { |v| to_hash_value(v) }
      when Array
        value.map { |v| to_hash_value(v) }
      else
        value
      end
    end
  end
end
