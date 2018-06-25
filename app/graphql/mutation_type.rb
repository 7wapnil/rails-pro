MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  field :signIn, function: Account::SignIn.new

  field :testField, types.String do
    description 'An example mutation field'
    resolve ->(_obj, _args, _ctx) do
      'Hello World!'
    end
  end
end
