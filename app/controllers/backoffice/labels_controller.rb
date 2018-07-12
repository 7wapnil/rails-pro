module Backoffice
  class LabelsController < BackofficeController
    def index
      @search = Label.search(query_params)
      @labels = @search.result.page(params[:page])
    end

    def new
      @label = Label.new
    end

    def edit
      @label = Label.find(params[:id])
    end

    def create
      @label = Label.new(label_params)

      if @label.save
        log_record_event :label_created, @label
        redirect_to backoffice_labels_path
      else
        render 'new'
      end
    end

    def update
      @label = Label.find(params[:id])

      if @label.update(label_params)
        log_record_event :label_updated, @label
        redirect_to backoffice_labels_path
      else
        render 'edit'
      end
    end

    def destroy
      @label = Label.find(params[:id])
      @label.destroy
      log_record_event :label_deleted, @label

      redirect_to backoffice_labels_path
    end

    private

    def label_params
      params.require(:label).permit(:name, :description)
    end
  end
end
