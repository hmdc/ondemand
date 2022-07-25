class ConfigurationProperty

  def self.with_boolean_mapper(name:, default_value: nil, read_from_env: false, env_name: nil)
    ConfigurationProperty.new(name, default_value, read_from_env, env_name, BooleanMapper)
  end

  def self.with_integer_mapper(name:, default_value: nil, read_from_env: false, env_name: nil)
    ConfigurationProperty.new(name, default_value, read_from_env, env_name, IntegerMapper)
  end

  def self.property(name:, default_value: nil, read_from_env: false, env_name: nil)
    ConfigurationProperty.new(name, default_value, read_from_env, env_name, PassThroughMapper)
  end

  attr_reader :name, :default_value, :read_from_environment, :environment_name
  alias_method :read_from_environment?, :read_from_environment

  def initialize(name, default_value, read_from_env, env_name, mapper)
    @name = name.to_sym
    @default_value = default_value
    @read_from_environment = read_from_env
    @mapper = mapper

    environment_name = env_name || "OOD_#{@name.to_s.upcase}"
    @environment_name = environment_name if @read_from_environment
  end

  def map_string(value)
    @mapper.map_string(value)
  end

  class PassThroughMapper
    def self.map_string(string_value)
      string_value
    end
  end

  class IntegerMapper
    def self.map_string(string_value)
      string_value.nil? ? string_value : Integer(string_value.to_s)
    rescue ArgumentError
      Rails.logger.error("Error parsing Integer property: #{string_value}")
      nil
    end
  end

  class BooleanMapper
    def self.map_string(string_value)
      string_value.nil? ? string_value : BooleanMapper.to_bool(string_value.to_s.upcase)
    end

    private
    FALSE_VALUES = ['', '0', 'F', 'FALSE', 'OFF', 'NO'].freeze
    
    def self.to_bool(value)
      !FALSE_VALUES.include?(value)
    end

  end

end