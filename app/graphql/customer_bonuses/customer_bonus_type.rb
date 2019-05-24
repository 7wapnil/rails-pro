# frozen_string_literal: true

module CustomerBonuses
  CustomerBonusType = GraphQL::ObjectType.define do
    name 'CustomerBonus'

    field :id, !types.ID
    field :code, !types.String
    field :rolloverBalance, !types.Float,
          property: :rollover_balance
    field :rolloverInitialValue, !types.Float,
          property: :rollover_initial_value
    field :status, !types.String
    field :maxRolloverPerBet, !types.Float,
          property: :max_rollover_per_bet
    field :minOddsPerBet, !types.Float,
          property: :min_odds_per_bet
    field :validForDays, !types.Int,
          property: :valid_for_days
    field :expiresAt, !types.String do
      resolve ->(obj, _args, _ctx) { obj.expires_at(human: true) }
    end
    field :amount, !types.String do
      resolve ->(obj, _atgs, _ctx) { obj.amount(human: true) }
    end
  end
end
