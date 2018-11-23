class ApiController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def current_customer
    return nil if request.headers['Authorization'].blank?

    token = request.headers['Authorization'].split(' ').last
    return nil if token.blank?

    result = JwtService.decode(token)
    user = User.find_by(id: result[0]['impersonated_by'])
    customer = Customer.find_by(id: result[0]['id'])

    if user.present?
      ImpersonatedCustomerDecorator.new(customer, user)
    else
      customer
    end
  rescue JWT::DecodeError
    nil
  end
end
