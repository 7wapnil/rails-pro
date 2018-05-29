module Backoffice
  class CustomersController < BackofficeController
    def index
      @search = Customer.search(query_params)
      @customers = @search.result.page(params[:page])
    end

    def show
      @customer = Customer.find(params[:id])
    end
  end
end
