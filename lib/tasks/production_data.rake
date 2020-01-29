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

    task refresh_counted_towards_rollover: :environment do
      Bet.where(status: Bet::ACCEPTED, counted_towards_rollover: true)
         .update_all(counted_towards_rollover: false)
    end

    desc 'Avoid getting into the pending state when re-settlement'
    task populate_bet_leg_statuses: :environment do
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE bet_legs
        SET settlement_status = bets.settlement_status
        FROM bet_legs BetLegsScope
        INNER JOIN bets
          ON bets.id = BetLegsScope.bet_id
        WHERE BetLegsScope.id = bet_legs.id AND
              bets.combo_bets IS FALSE AND
              bet_legs.settlement_status IS NULL AND
              bets.settlement_status IS NOT NULL AND
              bets.status IN ('settled','pending_manual_settlement');
      SQL
    end
  end

  namespace :labels do
    desc 'Create system labels'
    task add_system_labels: :environment do
      Label::RESERVED_BY_SYSTEM.each do |name|
        Label.find_by(name: I18n.t("labels.#{name}"),
                      kind: Label::CUSTOMER)
             &.destroy

        Label.new(keyword: name,
                  system: true,
                  kind: Label::CUSTOMER)
             .save(validate: false)
      end
    end
  end

  desc 'Generate slugs'
  task generate_slugs: :environment do
    Event.where("slug IS NULL OR slug = ''").find_each(&:save)
    Title.where("slug IS NULL OR slug = ''").find_each(&:save)
    EventScope.where("slug IS NULL OR slug = ''").find_each(&:save)
    EveryMatrix::Category.where("context IS NULL OR context = ''")
                         .find_each(&:save)
    EveryMatrix::ContentProvider.where("slug IS NULL OR slug = ''")
                                .find_each(&:save)
    EveryMatrix::Vendor.where("slug IS NULL OR slug = ''").find_each(&:save)
    EveryMatrix::PlayItem.where("slug IS NULL OR slug = ''").find_each(&:save)
  end
end
