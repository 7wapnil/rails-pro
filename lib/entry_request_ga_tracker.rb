# frozen_string_literal: true

class EntryRequestGaTracker
  def initialize(entry_request)
    @entry_request = entry_request
  end

  def track_deposit_success!
    ga_client.track_event(deposit_success_payload)
  end

  private

  attr_reader :entry_request

  def ga_client
    ::GaTracker.new(ENV['GA_TRACKER_ID'], client_id, ga_base_options)
  end

  def client_id
    entry_request.customer.customer_data&.ga_client_id
  end

  def ga_base_options
    {
      user_id: entry_request.customer.id
      # user_ip: entry_request.customer.last_visit_ip.to_s
    }
  end

  def deposit_success_payload
    {
      category: 'Payment',
      action: 'depositSuccesful',
      label: entry_request.customer.id,
      value: (base_currency_amount * 100).to_i
    }
  end

  def base_currency_amount
    Exchanger::Converter.call(entry_request.amount, entry_request.currency.code)
  end
end
