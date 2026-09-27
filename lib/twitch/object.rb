module Twitch
  # A lightweight wrapper around API response data. Attributes can be read with dot notation
  # (object.id) or like a hash (object[:id] or object["id"]). Nested hashes are wrapped too.
  class Object
    def initialize(attributes = {})
      @attributes = {}
      (attributes || {}).each { |key, val| self[key] = val }
    end

    def [](key)
      @attributes[key.to_sym]
    end

    def []=(key, val)
      @attributes[key.to_sym] = wrap(val)
    end

    def key?(key)
      @attributes.key?(key.to_sym)
    end

    def dig(key, *rest)
      val = self[key]
      rest.empty? || val.nil? ? val : val.dig(*rest)
    end

    def each_pair(&block)
      return enum_for(:each_pair) unless block_given?

      @attributes.each_pair(&block)
      self
    end

    # Returns the attributes as a hash, with nested objects converted to hashes too,
    # so the result can be serialized
    def to_h(&block)
      hash = @attributes.transform_values { |val| unwrap(val) }
      block ? hash.to_h(&block) : hash
    end

    def as_json(*)
      to_h
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    def ==(other)
      other.is_a?(Twitch::Object) && to_h == other.to_h
    end
    alias eql? ==

    def hash
      to_h.hash
    end

    def inspect
      attrs = @attributes.map { |key, val| "#{key}=#{val.inspect}" }.join(", ")
      "#<#{self.class.name}#{" " unless attrs.empty?}#{attrs}>"
    end
    alias to_s inspect

    private

    # Unknown attributes return nil, like a hash
    def method_missing(name, *args)
      if name.end_with?("=") && args.size == 1
        self[name.to_s.chomp("=")] = args.first
      elsif args.empty? && !name.end_with?("=", "?", "!")
        self[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      key?(name.to_s.chomp("=")) || super
    end

    def wrap(val)
      case val
      when Twitch::Object then val
      when Hash then Twitch::Object.new(val)
      when Array then val.map { |v| wrap(v) }
      else val
      end
    end

    def unwrap(val)
      case val
      when Twitch::Object then val.to_h
      when Array then val.map { |v| unwrap(v) }
      else val
      end
    end
  end
end
