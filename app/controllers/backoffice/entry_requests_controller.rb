module Backoffice
  class EntryRequestsController < BackofficeController
    def index
      @search = EntryRequest.search(query_params)
      @requests = @search.result.page(params[:page])
    end

    def show
      @request = EntryRequest.find(params[:id])
    end

    def create
      entry_request = EntryRequest.new(payload_params)

      if entry_request.save
        flash[:success] = t(:created, instance: t('entities.entry_request'))
        redirect_to backoffice_customer_path(entry_request.customer)
      else
        flash[:error] = entry_request.errors.full_messages
        redirect_back fallback_location: root_path
      end
    end

    private

    def payload_params
      params
        .require(:entry_request)
        .permit(:customer_id, :currency_id, :amount, :kind, :comment)
        .merge(origin_id: current_user.id, origin_type: :user)
    end
  end
end
