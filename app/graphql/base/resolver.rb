# frozen_string_literal: true

module Base
  class Resolver < GraphQL::Function
    include Decoratable
    include ::Base::Cacheable

    attr_reader :current_customer

    class << self
      attr_accessor :trackable

      def decorator_enabled?
        @decorator_class.present?
      end

      def pagination_enabled?
        type.to_s.match?(/Pagination$/)
      end

      def mark_as_trackable
        @trackable = true
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
      log_activity @current_customer, @request if self.class.trackable
      resolve(obj, args)
    end

    def resolve(_obj, _args)
      raise NotImplementedError
    end

    protected

    def log_activity(customer, request)
      Customers::VisitLogService.call customer, request
    end

    def check_auth
      not_authenticated = auth_protected? && @current_customer.blank?
      raise GraphQL::ExecutionError, 'AUTH_REQUIRED' if not_authenticated
    end
  end
end
