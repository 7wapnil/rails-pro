namespace :production_data do
  namespace :bets do
    desc 'Rename pending_manual_cancellation status to pending_mts_cancellation'
    task rename_pmc_status: :environment do
      Bet.where(status: 'pending_manual_cancellation')
         .update_all(status: Bet::PENDING_MTS_CANCELLATION)
    end

    desc 'Migrate odd data to bet_legs table'
    task create_bet_legs: :environment do
      ActiveRecord::Base.connection.execute(
        <<~SQL
          INSERT INTO bet_legs (
            bet_id, odd_id, odd_value,
            notification_message, notification_code,
            created_at, updated_at
          )
          SELECT
            bets.id, bets.odd_id, bets.odd_value,
            bets.notification_message, bets.notification_code,
            bets.created_at, bets.updated_at
          FROM bets
          LEFT JOIN bet_legs ON bet_legs.bet_id = bets.id
          WHERE bet_legs.id IS NULL
      SQL
      )
    end

    task delete_invalid_audit_logs: :environment do
      AuditLog.where(event: 'entry_request_created', context: nil).delete_all
    end
  end
end
