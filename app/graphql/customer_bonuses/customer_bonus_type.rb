# frozen_string_literal: true

module CustomerBonuses
  CustomerBonusType = GraphQL::ObjectType.define do
    name 'CustomerBonus'

    field :id, !types.ID
    field :code, !types.String
    field :rolloverBalance, !types.Float do
      resolve ->(obj, _args, _ctx) { obj.rollover_balance.to_f }
    end
    field :rolloverInitialValue, !types.Float do
      resolve ->(obj, _args, _ctx) { obj.rollover_initial_value.to_f }
    end
    field :status, !types.String
    field :maxRolloverPerBet, !types.Float,
          property: :max_rollover_per_bet
    field :minOddsPerBet, !types.Float,
          property: :min_odds_per_bet
    field :validForDays, !types.Int,
          property: :valid_for_days
    field :expiresAt, !types.String do
      resolve ->(obj, _args, _ctx) { obj.active_until_date(human: true) }
    end
    field :amount, !types.String do
      resolve ->(obj, _atgs, _ctx) { obj.amount(human: true) }
    end
    field :casino, !types.Boolean
    field :sportsbook, !types.Boolean
  end
end
