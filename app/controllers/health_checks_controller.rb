class HealthChecksController < ActionController::Base
  def show
    render json: { success: true }
  end
end
