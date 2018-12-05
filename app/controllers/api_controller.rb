class ApiController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def current_customer
    Customer.find_by(id: jwt_decoded_data['id'])
  end

  def impersonated_by
    User.find_by(id: jwt_decoded_data['impersonated_by'])
  end

  private

  def jwt_decoded_data
    return {} if request.headers['Authorization'].blank?

    token = request.headers['Authorization'].split(' ').last
    return {} if token.blank?

    JwtService.decode(token).first
  rescue JWT::DecodeError
    {}
  end
end
