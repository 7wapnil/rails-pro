# frozen_string_literal: true

class CustomersFilter
  attr_reader :source, :params

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @params = query_params
    @query_params = prepare_label_filter(query_params)
    @page = page

    format_ip_address!
  end

  def search
    @source.ransack(@query_params, search_key: :customers)
  end

  def customers
    search
      .result
      .order(id: :desc)
      .page(@page)
      .includes(:labels, :system_labels, :address)
      .decorate
  end

  def available_labels
    Label.customer
         .decorate
         .sort_by { |label| [label.system? ? 0 : 1, label.decorated_name] }
  end

  private

  def prepare_label_filter(query_params)
    return query_params unless query_params[:agg_labels_matches_all].present?

    ilike_label_ids = query_params[:agg_labels_matches_all]
                      .reject(&:blank?)
                      .map { |id| "%|#{id}|%" }
    query_params.merge(agg_labels_matches_all: ilike_label_ids)
  end

  def format_ip_address!
    return if @query_params[:ip_address_eq].blank?

    @query_params[:ip_address_eq] = IPAddr.new(@query_params[:ip_address_eq])
  rescue IPAddr::InvalidAddressError
    @query_params[:ip_address_eq] = nil
  end
end
