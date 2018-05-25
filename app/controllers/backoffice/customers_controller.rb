module Backoffice
  class CustomersController < BackofficeController
    def index
      @customers = Customer.page params[:page]
    end

    def show
      @customer = Customer.find(params[:id])
    end
  end
end
