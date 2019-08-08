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

  field :placeBets, function: Betting::Place.new
  field :deleteFile, function: Documents::DeleteFile.new

  field :depositBonus, function: Deposits::DepositBonusQuery.new

  field :deposit, function: ::Payments::Deposits::Perform.new
  field :withdraw, function: ::Payments::Withdrawals::Perform.new
end
