# frozen_string_literal: true

require 'graphql/batch'

ArcanebetSchema = GraphQL::Schema.define do
  use GraphQL::Batch
  use GraphQL::Subscriptions::ActionCableSubscriptions,
      serializer: GraphqlExtensions::Subscriptions::Serializer

  mutation(MutationType)
  query(QueryType)
  subscription(SubscriptionType)

  resolve_type ->(*) {}
end

GraphQL::Errors.configure(ArcanebetSchema) do
  rescue_from ::ResolvingError do |exception, _obj, _args, ctx|
    exception.errors_map.each do |key, value|
      error = GraphQL::ExecutionError.new(value)
      error.path = [camelize_symbol(key)]
      ctx.add_error(error)
    end
    ctx.errors.pop
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    GraphQL::ExecutionError.new(exception.message)
  end

  rescue_from ActiveRecord::RecordInvalid do |exception, _obj, _args, ctx|
    exception.record.errors.details.keys.map do |attribute|
      error = GraphQL::ExecutionError.new(
        exception.record.errors.full_messages_for(attribute).first
      )
      error.path = [camelize_symbol(attribute)]
      ctx.add_error(error)
    end
    ctx.errors.pop
  end

  rescue_from ActiveModel::ValidationError do |exception, _obj, _args, ctx|
    exception.model.errors.details.keys.each do |attribute|
      error = GraphQL::ExecutionError.new(
        exception.model.errors.full_messages_for(attribute).first
      )
      error.path = [camelize_symbol(attribute)]
      ctx.add_error(error)
    end

    nil
  end

  rescue_from StandardError do |exception|
    GraphQL::ExecutionError.new(exception.message)
  end
end

def camelize_symbol(sym)
  sym.to_s.camelize(:lower).to_sym
end
