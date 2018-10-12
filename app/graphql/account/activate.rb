module Account
  class Activate < ::Base::Resolver
    argument :token, !types.String

    type !types.Boolean

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      customer = Customer.find_by!(activation_token: args[:token])
      if customer.activated
        raise GraphQL::ExecutionError, 'Customer already activated'
      end

      customer.update(activated: true)
      true
    end
  end
end
