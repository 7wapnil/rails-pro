# frozen_string_literal: true

module FilterHelper
  def search_date_for(key, parent_key = nil, allow_nil = true)
    return parse_date(query_params[key], allow_nil) if parent_key.nil?

    parse_date(query_params(parent_key)[key], allow_nil)
  end

  private

  def parse_date(date, allow_nil)
    return date&.to_date if allow_nil

    date&.to_date || Time.zone.now
  end
end
