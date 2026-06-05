# Used to normalise Aliyun's CamelCase JSON responses into snake_case symbol keys.
class Hash
  def keys_to_snake_case
    deep_transform_keys { |key| key.to_s.underscore.to_sym }
  end

  def keys_to_lower_camel_case
    deep_transform_keys { |key| key.to_s.camelize(:lower) }
  end
end
