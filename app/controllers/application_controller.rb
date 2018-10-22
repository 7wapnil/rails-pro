class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :query_params
  def current_customer
    nil
  end

  protected

  def query_params
    query = params[:query].dup
    return {} unless query

    query.each do |key, value|
      query[key] = value.is_a?(Array) ? value.map(&:squish) : value.squish
    end
    query
  end
end
