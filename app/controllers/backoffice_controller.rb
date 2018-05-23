class BackofficeController < ActionController::Base
  layout 'backoffice'

  before_action :authenticate_user!
end
