# frozen_string_literal: true

class CustomersFilter
  attr_reader :source

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = query_params
    @page = page

    format_ip_address!
  end

  def search
    @source.ransack(@query_params, search_key: :customers)
  end

  def customers
    search.result.order(id: :desc).page(@page)
  end

  private

  def format_ip_address!
    return if @query_params[:ip_address_eq].blank?

    @query_params[:ip_address_eq] = IPAddr.new(@query_params[:ip_address_eq])
  rescue IPAddr::InvalidAddressError
    @query_params[:ip_address_eq] = nil
  end
end
