module Authentication
  extend ActiveSupport::Concern

  included do
    @auth_opts = { source: :headers, key: 'Authorization' }
  end

  module ClassMethods
    attr_reader :auth_opts

    def authenticatable(options = {})
      @auth_opts = @auth_opts.merge(options)
    end
  end

  def current_customer
    Customer.find_by(id: jwt_decoded_data['id'])
  end

  def impersonated_by
    User.find_by(id: jwt_decoded_data['impersonated_by'])
  end

  private

  def jwt_decoded_data
    token = parsed_request.split(' ').last
    return {} if token.blank?

    JwtService.decode(token).first
  rescue JWT::DecodeError
    {}
  end

  def parsed_request
    token_source[options[:key]] || ''
  end

  def token_source
    options[:source] == :query ? request.params : request.headers
  end

  def options
    return self.class.auth_opts if self.class.auth_opts.present?

    self.class.superclass.auth_opts
  end
end
