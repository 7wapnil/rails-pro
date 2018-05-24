module Backoffice
  class CustomersController < BackofficeController
    def index
      @customers = Customer.all
    end

    def show
      @customer = Customer.find(params[:id])
    end
  end
end
