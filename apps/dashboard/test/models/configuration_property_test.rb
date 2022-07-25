require 'test_helper'

class ConfigurationPropertyTest < ActiveSupport::TestCase

  test "check ConfigurationProperty.property defaults" do
    ConfigurationProperty.expects(:new).with("property_name", nil, false, nil, ConfigurationProperty::PassThroughMapper).once
    ConfigurationProperty.property(name: "property_name")
  end

  test "check ConfigurationProperty.property pass arguments to constructor" do
    ConfigurationProperty.expects(:new).with("property_name", [], true, "env_name", ConfigurationProperty::PassThroughMapper).once
    ConfigurationProperty.property(name: "property_name", default_value: [], read_from_env: true, env_name: "env_name")
  end

  test "check ConfigurationProperty.with_boolean_mapper defaults" do
    ConfigurationProperty.expects(:new).with("property_name", nil, false, nil, ConfigurationProperty::BooleanMapper).once
    ConfigurationProperty.with_boolean_mapper(name: "property_name")
  end

  test "check ConfigurationProperty.with_boolean_mapper pass arguments to constructor" do
    ConfigurationProperty.expects(:new).with("property_name", true, true, "env_name", ConfigurationProperty::BooleanMapper).once
    ConfigurationProperty.with_boolean_mapper(name: "property_name", default_value: true, read_from_env: true, env_name: "env_name")
  end

  test "check ConfigurationProperty.with_integer_mapper defaults" do
    ConfigurationProperty.expects(:new).with("property_name", nil, false, nil, ConfigurationProperty::IntegerMapper).once
    ConfigurationProperty.with_integer_mapper(name: "property_name")
  end

  test "check ConfigurationProperty.with_integer_mapper pass arguments to constructor" do
    ConfigurationProperty.expects(:new).with("property_name", 10, true, "env_name", ConfigurationProperty::IntegerMapper).once
    ConfigurationProperty.with_integer_mapper(name: "property_name", default_value: 10, read_from_env: true, env_name: "env_name")
  end

  test "name should should be transform to symbol" do
    target = ConfigurationProperty.new("property_name", nil, false, nil, ConfigurationProperty::PassThroughMapper)
    assert_equal :property_name,  target.name
  end

  test "environment_name should default to nil when read_from_env is false" do
    target = ConfigurationProperty.new("name", nil, false, "env_name", ConfigurationProperty::PassThroughMapper)

    assert_equal false,  target.read_from_environment?
    assert_nil target.environment_name
  end

  test "environment_name should be created based on name when read_from_env is true and no env_name is set" do
    target = ConfigurationProperty.new("property_name", nil, true, nil, ConfigurationProperty::PassThroughMapper)

    assert_equal true,  target.read_from_environment?
    assert_equal "OOD_PROPERTY_NAME",  target.environment_name
  end

  test "environment_name should be env_name argument when read_from_env is true and env_name is set" do
    target = ConfigurationProperty.new("property_name", nil, true, "environment_name_override", ConfigurationProperty::PassThroughMapper)

    assert_equal true,  target.read_from_environment?
    assert_equal "environment_name_override",  target.environment_name
  end

  test "Mappers should return nil when string is nil" do
    assert_nil ConfigurationProperty::BooleanMapper.map_string(nil)
    assert_nil ConfigurationProperty::IntegerMapper.map_string(nil)
    assert_nil ConfigurationProperty::PassThroughMapper.map_string(nil)
  end

  test "BooleanMapper.map_string should parse strings into booleans ignoring case" do
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("false")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("FalSe")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("off")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("no")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("f")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("0")
    assert_equal false,  ConfigurationProperty::BooleanMapper.map_string("")

    assert_equal true,  ConfigurationProperty::BooleanMapper.map_string("true")
    assert_equal true,  ConfigurationProperty::BooleanMapper.map_string("TruE")
  end

  test "IntegerMapper.map_string should parse integers" do
    assert_equal 10,  ConfigurationProperty::IntegerMapper.map_string("10")
    assert_equal -10,  ConfigurationProperty::IntegerMapper.map_string("-10")
  end

  test "IntegerMapper.map_string should return nil for invalid integers" do
    assert_nil ConfigurationProperty::IntegerMapper.map_string("invalid")
    assert_nil ConfigurationProperty::IntegerMapper.map_string("10.invalid")
  end

end