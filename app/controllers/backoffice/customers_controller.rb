module Backoffice
  class CustomersController < BackofficeController
    def index
      @search = Customer.search(query_params)
      @customers = @search.result.page(params[:page])
    end

    def show
      @customer = Customer.find(params[:id])
      @labels = Label.all
    end

    def add_label
      customer = Customer.find(params[:id])
      customer.labels << Label.find(label_param[:id])
    end

    def remove_label
      customer = Customer.find(params[:id])
      customer.labels.delete(Label.find(label_param[:id]))
    end

    private

    def label_param
      params.require(:label).permit(:id)
    end
  end
end
