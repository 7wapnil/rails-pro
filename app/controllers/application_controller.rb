class ApplicationController < ActionController::Base

  protected

  def origin_params
    { origin_kind: :user,
      origin_id: current_user&.id || current_customer&.id }
  end

end
