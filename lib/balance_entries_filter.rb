class BalanceEntriesFilter
  attr_reader :source

  def initialize(source:, query_params: {}, page: nil, per_page: 10)
    @source = source
    @query_params = query_params
    if @query_params[:created_at_lteq].present?
      @query_params[:created_at_lteq] = \
        I18n.l(Date.parse(@query_params[:created_at_lteq]) + 1.day)
    end
    @page = page
    @per_page = per_page
  end

  def search
    @search ||= @source.ransack(@query_params, search_key: :entries)
  end

  def balance_entries
    search.sorts = ['created_at desc'] if search.sorts.empty?
    search.result.page(@page).per(@per_page)
  end
end
