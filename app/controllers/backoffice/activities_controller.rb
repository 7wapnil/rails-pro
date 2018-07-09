module Backoffice
  class ActivitiesController < BackofficeController
    def index
      @activities = AuditLog.all
      @formatter = Audit::Formatter.new
    end
  end
end
