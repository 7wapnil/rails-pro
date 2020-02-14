namespace :production_data do
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

  namespace :every_matrix do
    desc 'Set all every matrix entities as activated'
    task set_as_activated: :environment do
      %i[every_matrix_play_items
         every_matrix_vendors
         every_matrix_content_providers].each do |table|
        ActiveRecord::Base
          .connection
          .execute("UPDATE #{table} SET external_status = 'activated'")
      end
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
end
