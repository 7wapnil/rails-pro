require 'graphql/batch'

ArcanebetSchema = GraphQL::Schema.define do
  use GraphQL::Subscriptions::ActionCableSubscriptions
  use GraphQL::Batch

  mutation(MutationType)
  query(QueryType)
  subscription(SubscriptionType)
end

GraphQL::Errors.configure(ArcanebetSchema) do
  rescue_from ActiveRecord::RecordNotFound do |exception|
    GraphQL::ExecutionError.new(exception.message)
  end

  rescue_from ActiveRecord::RecordInvalid do |exception, _obj, _args, ctx|
    exception.record.errors.details.keys.map do |attribute|
      error = GraphQL::ExecutionError.new(
        exception.record.errors.full_messages_for(attribute).first
      )
      error.path = attribute
      ctx.add_error(error)
    end
    raise GraphQL::ExecutionError, 'Invalid record'
  end

  rescue_from ActiveModel::ValidationError do |exception, _obj, _args, ctx|
    exception.model.errors.details.keys.map do |attribute|
      error = GraphQL::ExecutionError.new(
        exception.model.errors.full_messages_for(attribute).first
      )
      error.path = attribute
      ctx.add_error(error)
    end
    raise GraphQL::ExecutionError, 'Invalid record'
  end

  rescue_from StandardError do |exception|
    GraphQL::ExecutionError.new(exception.message)
  end
end
