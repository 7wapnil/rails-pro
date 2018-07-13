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

    def account_management
      @customer = Customer.find(params[:id])
      @entry_request = EntryRequest.new(customer: @customer)
      @entry_requests = @customer.entry_requests.page(params[:page])
    end

    def activity
      @customer = Customer.find(params[:id])
      @entries = @customer.entries.page(params[:page])
      @audit_logs = AuditLog.page(params[:page])
    end

    def notes
      @customer = Customer.find(params[:id])
      @note = CustomerNote.new(customer: @customer)
      @customer_notes = @customer.customer_notes.page(params[:page]).per(5)
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
