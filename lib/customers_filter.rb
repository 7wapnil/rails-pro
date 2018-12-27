class CustomersFilter
  attr_reader :customers_source

  def initialize(customers_source:, query_params: {}, page: nil)
    @customers_source = customers_source
    @query_params = query_params
    @page = page
  end

  def search
    @customers_source.ransack(@query_params, search_key: :customers)
  end

  def customers
    search.result.order(id: :desc).page(@page)
  end
end
