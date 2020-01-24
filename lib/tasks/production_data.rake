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
        execute("UPDATE #{table} SET external_status = 'activated'")
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
  end
end
