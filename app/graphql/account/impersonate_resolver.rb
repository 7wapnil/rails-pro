# frozen_string_literal: true

module Account
  class ImpersonateResolver < ApplicationService
    def initialize(token:, ip_address:)
      @token = token
      @ip_address = ip_address
    end

    def call
      OpenStruct.new(user: customer, token: token)
    rescue ActiveRecord::RecordNotFound => error
      Rails.logger.error(
        message: 'Impersonation attempt with malformed token!',
        token: token,
        ip_address: ip_address,
        error_object: error
      )

      raise error
    end

    private

    attr_reader :token, :ip_address

    def read_jwt_token
      JwtService.decode(token)
                .first
                .yield_self { |payload| payload.is_a?(Hash) ? payload : {} }
    rescue JWT::DecodeError, JWT::ExpiredSignature
      {}
    end

    def customer
      @customer ||= Customer
                    .includes(wallets: :currency)
                    .find_by!(id: read_jwt_token['id'])
    end
  end
end
