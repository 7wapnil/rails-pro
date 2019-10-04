namespace :bet_settlement do
  desc 'Assign achieved_at date to manual settled bets'
  task set_achieved_date: :environment do
    Bet
      .where(status: Bet::MANUALLY_SETTLED,
             bet_settlement_status_achieved_at: nil)
      .update_all('bet_settlement_status_achieved_at = updated_at')
  end
end
