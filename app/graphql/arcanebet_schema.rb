ArcanebetSchema = GraphQL::Schema.define do
  # Comment this out when you have a mutation type
  # There's a bug that breaks GraphiQL if
  # blank mutation is present in the schema

  mutation(MutationType)
  query(QueryType)
end

GraphQL::Errors.configure(ArcanebetSchema) do
  rescue_from ActiveRecord::RecordNotFound do
    nil
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

  rescue_from StandardError do |exception|
    GraphQL::ExecutionError.new(exception.message)
  end
end
