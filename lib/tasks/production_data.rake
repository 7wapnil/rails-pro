namespace :production_data do
  namespace :bets do
    desc 'Rename pending_manual_cancellation status to pending_mts_cancellation'
    task rename_pmc_status: :environment do
      Bet.where(status: 'pending_manual_cancellation')
         .update_all(status: Bet::PENDING_MTS_CANCELLATION)
    end

    task delete_invalid_audit_logs: :environment do
      AuditLog.where(event: 'entry_request_created', context: nil).delete_all
    end
  end
end
