module DateIntervalFilters
  extend ActiveSupport::Concern

  def prepare_interval_filter(query_params, date_field)
    interval = {}
    to_key = "#{date_field}_lteq".to_sym
    to = query_params[to_key]
    to = to&.to_date&.end_of_day
    from_key = "#{date_field}_gteq".to_sym
    from = query_params[from_key]
    from = from&.to_date&.beginning_of_day
    interval[from_key] = from
    interval[to_key] = to

    query_params.merge interval
  end
end
