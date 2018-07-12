module Backoffice
  class ActivitiesController < BackofficeController
    def index
      @activities = AuditLog.page(params[:page])
      @formatter = Audit::Formatter.new
    end

    def show
      @activity = AuditLog.find_by(id: params[:id])
      @formatter = Audit::Formatter.new
    end
  end
end
