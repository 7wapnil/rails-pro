class ApiController < ActionController::Base
  def current_customer
    return nil if request.headers['Authorization'].blank?
    token = request.headers['Authorization'].split(' ').last
    return nil if token.blank?
    result = JwtService.decode(token)
    Customer.find_by(id: result[0]['id'])
  rescue JWT::DecodeError
    nil
  end
end
