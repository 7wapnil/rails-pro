module Backoffice
  class EntryRequestsController < BackofficeController
    def index
      @search = EntryRequest.search(query_params)
      @requests = @search.result.page(params[:page])
    end
  end
end
