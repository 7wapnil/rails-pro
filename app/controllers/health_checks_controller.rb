class HealthChecksController < ApplicationController
  def show
    render json: { success: true }
  end
end
