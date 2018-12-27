class CustomersFilter
  attr_reader :source

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = query_params
    @page = page
  end

  def search
    @source.ransack(@query_params, search_key: :customers)
  end

  def customers
    search.result.order(id: :desc).page(@page)
  end
end
