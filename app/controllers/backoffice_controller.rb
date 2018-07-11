class BackofficeController < ActionController::Base
  layout 'backoffice'

  before_action :authenticate_user!

  protected

  def query_params
    query = params[:query].dup
    return unless query

    query.each { |key, value| query[key] = value.squish }
    query
  end
end
