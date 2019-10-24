# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  def cache_if_enabled(&_block)
    return Rails.cache.read(cache_key) if Rails.cache.exist?(cache_key)

    fetch_cache(yield)
  end

  def cache_key
    "#{query_name}-#{query_variables}"
  end

  def fetch_cache(obj)
    return obj unless obj.context['cache'].present?

    Rails.cache.fetch(cache_key, expires_in: obj.context['cache']) { obj.to_h }
  end

  def query_name
    document.definitions&.first&.name
  end

  def query_variables
    Base64.encode64(params[:variables].to_s)
  end

  def document
    raise NotImplementedError
  end
end
