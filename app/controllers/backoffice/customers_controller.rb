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

    def update_labels
      customer = Customer.find(params[:id])
      if labels_params[:ids].include? '0'
        customer.labels.clear
      else
        customer.label_ids = labels_params[:ids]
      end
    end

    private

    def labels_params
      params.require(:labels).permit(ids: [])
    end
  end
end
