class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def current_customer
    nil
  end

  protected

  def query_params
    query = params[:query].dup
    return unless query

    query.each { |key, value| query[key] = value.squish }
    query
  end
end
