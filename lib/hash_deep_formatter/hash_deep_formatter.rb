class HashDeepFormatter
  def self.deep_transform_keys(hash, &block)
    formatted_hash = {}
    hash.each do |k, v|
      value = v
      value = deep_transform_keys(v, &block) if v.is_a?(Hash)
      if v.is_a?(Array)
        value =
          v.map { |e| e.is_a?(Hash) ? deep_transform_keys(e, &block) : e }
      end
      formatted_hash[ yield(k) ] =
        value
    end
    formatted_hash
  end
end
