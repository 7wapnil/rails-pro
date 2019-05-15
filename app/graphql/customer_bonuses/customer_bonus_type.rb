# frozen_string_literal: true

module CustomerBonuses
  CustomerBonusType = GraphQL::ObjectType.define do
    name 'CustomerBonus'

    field :id, !types.ID
    field :code, !types.String
    field :rollover_balance, !types.Float
    field :rollover_initial_value, !types.Float
    field :status, !types.String
    field :max_rollover_per_bet, !types.Float
    field :min_odds_per_bet, !types.Float
    field :valid_for_days, !types.Int
    field :expires_at, !types.String do
      resolve ->(obj, _args, _ctx) { obj.expires_at.strftime('%e.%m.%y') }
    end
  end
end
