class EntryRequestsFilter
  attr_reader :source

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = query_params
    @page = page
  end

  def search
    @source.ransack(@query_params, search_key: :entry_requests)
  end

  def requests
    search.result.page(@page)
  end
end
