module Base
  class Resolver < GraphQL::Function
    protected

    def check_auth(context)
      return unless context[:currenct_user].blank?
      raise GraphQL::ExecutionError, 'Authentication required'
    end
  end
end
