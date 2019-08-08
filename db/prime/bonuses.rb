puts 'Creating Bonuses ...'

Bonus.find_or_create_by!(code: 'bonus') do |bonus|
  bonus.kind = Bonus::DEPOSIT
  bonus.rollover_multiplier = 10
  bonus.max_rollover_per_bet = 200
  bonus.max_deposit_match = 200
  bonus.min_odds_per_bet = 1.5
  bonus.min_deposit = 10
  bonus.valid_for_days = 180
  bonus.expires_at = 3.months.from_now.end_of_month
  bonus.percentage = 100
  bonus.repeatable = true
end
