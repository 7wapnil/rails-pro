class ActivitiesController < ApplicationController
  def index
    @activities = AuditLog.page(params[:page])
  end

  def show
    @activity = AuditLog.find_by(id: params[:id])
  end
end
