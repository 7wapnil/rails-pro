module Base
  class Resolver < GraphQL::Function
    protected

    def check_auth(context)
      return unless context[:currenct_user].blank?
      raise GraphQL::ExecutionError, 'AUTH_REQUIRED'
    end
  end
end
