module Backoffice
  class ActivitiesController < BackofficeController
    def index
      @activities = AuditLog.page(params[:page])
    end

    def show
      @activity = AuditLog.find_by(id: params[:id])
    end
  end
end
