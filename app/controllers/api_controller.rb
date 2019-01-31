class ApiController < ActionController::Base
  include Authentication

  authenticatable source: :headers
  skip_before_action :verify_authenticity_token
end
