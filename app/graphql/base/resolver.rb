module Base
  class Resolver < GraphQL::Function
    def auth_protected?
      true
    end

    def call(obj, args, ctx)
      @current_customer = ctx[:current_customer]
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

    def log_event(event, context)
      Audit::Service.call(event: event,
                          origin_kind: :customer,
                          origin_id: @current_customer&.id,
                          context: context)
    end

    def log_record_event(event, record)
      log_event event, record.loggable_attributes
    end
  end
end
