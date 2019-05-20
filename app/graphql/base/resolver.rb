# frozen_string_literal: true

module Base
  class Resolver < GraphQL::Function
    include Decoratable

    attr_reader :current_customer

    class << self
      def decorator_enabled?
        @decorator_class.present?
      end

      def pagination_enabled?
        type.to_s.match?(/Pagination$/)
      end
    end

    def auth_protected?
      true
    end

    def call(obj, args, ctx)
      @request = ctx[:request]
      @current_customer = ctx[:current_customer]
      @impersonated_by = ctx[:impersonated_by]
      check_auth
      resolve(obj, args)
    end

    def resolve(_obj, _args)
      raise NotImplementedError
    end

    protected

    def check_auth
      not_authenticated = auth_protected? && @current_customer.blank?
      raise GraphQL::ExecutionError, 'AUTH_REQUIRED' if not_authenticated
    end
  end
end
