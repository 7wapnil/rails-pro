class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :query_params

  def current_customer
    nil
  end

  protected

  def query_params(key = :query)
    (params[key].dup || {}).transform_values do |value|
      value.is_a?(Array) ? value.map(&:squish) : value.squish
    end
  end
end
