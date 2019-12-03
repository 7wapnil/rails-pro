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
      collect_request_info!(ctx)

      authentication_check!
      check_if_customer_blocked! if current_customer

      log_activity(current_customer, @request) if self.class.trackable
      resolve(obj, args)
    end

    def resolve(_obj, _args)
      raise NotImplementedError
    end

    protected

    def collect_request_info!(ctx)
      @request = ctx[:request]
      @current_customer = ctx[:current_customer]
      @impersonated_by = ctx[:impersonated_by]
    end

    def authentication_check!
      return unless auth_protected? && current_customer.blank?

      raise GraphQL::ExecutionError, 'AUTH_REQUIRED'
    end

    def check_if_customer_blocked!
      return unless current_customer.locked?

      raise GraphQL::ExecutionError, 'BANNED'
    end

    def log_activity(customer, request)
      Customers::VisitLogService.call(customer, request)
    end
  end
end
