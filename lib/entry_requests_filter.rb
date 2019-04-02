class EntryRequestsFilter
  attr_reader :source

  def initialize(source:, query_params: {}, page: nil, per_page: 10)
    @source = source
    @query_params = query_params
    @page = page
    @per_page = per_page
  end

  def search
    @source.ransack(@query_params, search_key: :entry_requests)
  end

  def requests
    search.result.page(@page).per(@per_page)
  end
end
