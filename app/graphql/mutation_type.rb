MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  field :signIn, function: Account::SignIn.new
  field :signUp, function: Account::SignUp.new
  field :activate, function: Account::Activate.new
  field :changePassword, function: Account::ChangePassword.new

  field :placeBets, function: Betting::Place.new
  field :deleteFile, function: Documents::DeleteFile.new
end
