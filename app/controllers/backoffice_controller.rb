class BackofficeController < ApplicationController
  layout 'backoffice'

  before_action :authenticate_user!

  protected

  def query_params
    query = params[:query].dup
    return unless query

    query.each { |key, value| query[key] = value.delete(' ') }
    query
  end

  def origin_params
    { origin_kind: :user,
      origin_id: current_user&.id }
  end
end
