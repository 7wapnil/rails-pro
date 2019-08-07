# frozen_string_literal: true

class CustomerTransactionsFilter
  PER_PAGE = 10

  attr_reader :source

  def initialize(source:, query_params: {}, page: nil, per_page: PER_PAGE)
    @source = source
    @query_params = query_params
    @page = page
    @per_page = per_page

    setup_created_at_filter! if query_params[:created_at_lteq].present?
    set_default_sorting! if query_params[:s].blank?
  end

  def search
    @source
      .includes(:entry, :customer, entry_request: :currency)
      .ransack(@query_params, search_key: :customer_transactions)
  end

  def transactions
    @transactions ||= search.result.page(@page).per(@per_page)
  end

  private

  def setup_created_at_filter!
    @query_params[:created_at_lteq] =
      I18n.l(Date.parse(@query_params[:created_at_lteq]) + 1.day)
  end

  def set_default_sorting!
    @query_params[:s] = 'created_at desc'
  end
end
