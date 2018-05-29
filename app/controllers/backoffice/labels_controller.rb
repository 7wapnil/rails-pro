module Backoffice
  class LabelsController < BackofficeController
    def index
      @search = Label.search(query_params)
      @labels = @search.result.page(params[:page])
    end
  end
end
