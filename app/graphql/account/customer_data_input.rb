module Account
  CustomerDataInput = GraphQL::InputObjectType.define do
    name 'CustomerDataInput'

    argument :traffic_type_last, !types.String
    argument :utm_source_last, !types.String
    argument :utm_medium_last, !types.String
    argument :utm_campaign_last, !types.String
    argument :utm_content_last, !types.String
    argument :utm_term_last, !types.String
    argument :visitcount_last, !types.String
    argument :browser_last, !types.String
    argument :device_type_last, !types.String
    argument :device_platform_last, !types.String
    argument :registration_url_last, !types.String
    argument :timestamp_visit_last, !types.String
    argument :entrance_page_last, !types.String
    argument :referrer_last, !types.String
    argument :current_btag, types.String
    argument :traffic_type_first, !types.String
    argument :utm_source_first, !types.String
    argument :utm_medium_first, !types.String
    argument :utm_campaign_first, !types.String
    argument :utm_term_first, !types.String
    argument :timestamp_visit_first, !types.String
    argument :entrance_page_first, !types.String
    argument :referrer_first, !types.String
    argument :gaClientID, types.String
  end
end
