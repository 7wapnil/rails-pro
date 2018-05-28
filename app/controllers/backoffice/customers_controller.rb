module Backoffice
  class CustomersController < BackofficeController
    def index
      @search = Customer.search(query_params)
      @customers = @search.result.page(params[:page])
    end

    def show
      @customer = Customer.find(params[:id])
    end

    private

    def query_params
      query = params[:query].dup
      return unless query

      query.each { |key, value| query[key] = value.delete(' ') }
      query
    end
  end
end
