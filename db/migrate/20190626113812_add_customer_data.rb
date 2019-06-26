class AddCustomerData < ActiveRecord::Migration[5.2]
  def change
    create_table :customer_data do |t|
      t.references :customer, foreign_key: true
      t.string :traffic_type_last
      t.string :utm_source_last
      t.string :utm_medium_last
      t.string :utm_campaign_last
      t.string :utm_content_last
      t.string :utm_term_last
      t.string :visitcount_last
      t.string :browser_last
      t.string :device_type_last
      t.string :device_platform_last
      t.string :ip_last
      t.string :registration_url_last
      t.string :timestamp_visit_last
      t.string :entrance_page_last
      t.string :referrer_last
      t.string :current_btag
      t.string :traffic_type_first
      t.string :utm_source_first
      t.string :utm_medium_first
      t.string :utm_campaign_first
      t.string :utm_term_first
      t.string :timestamp_visit_first
      t.string :entrance_page_first
      t.string :referrer_first
      t.string :gaClientID
      t.timestamps
    end
  end
end
