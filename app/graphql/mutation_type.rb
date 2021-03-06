# frozen_string_literal: true

MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  field :signIn, function: Account::SignIn.new
  field :signUp, function: Account::SignUp.new
  field :activate, function: Account::Activate.new
  field :changePassword, function: Account::ChangePassword.new
  field :verifyEmail, function: Account::VerifyEmail.new
  field :requestPasswordReset, function: Account::RequestPasswordReset.new
  field :resetPassword, function: Account::ResetPassword.new
  field :impersonate, function: Account::Impersonate.new
  field :updateUser, function: Account::UpdateUser.new

  field :placeBets, function: Betting::Place.new
  field :placeComboBets, function: Betting::PlaceComboBets.new
  field :deleteFile, function: Documents::DeleteFile.new

  field :depositBonus, function: Deposits::DepositBonusQuery.new
  field :cancelActiveBonus, function: Account::CancelActiveBonus.new

  field :deposit, function: ::Payments::Deposits::Perform.new
  field :withdraw, function: ::Payments::Withdrawals::Perform.new

  field :createEveryMatrixSession, function: ::EveryMatrix::CreateSession.new
end
