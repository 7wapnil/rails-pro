module Backoffice
  class ActivitiesController < BackofficeController
    def index
      @activities = AuditLog.page(params[:page])
      @formatter = Audit::Formatter.new
    end
  end
end
