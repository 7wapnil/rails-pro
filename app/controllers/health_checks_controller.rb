class HealthChecksController < ActionController::Base
  def show
    render json: { success: true }
  end

  def current_customer
    nil
  end
end
