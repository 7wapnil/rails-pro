class CreateTranslationForTitles < ActiveRecord::Migration[5.2]
  def up
    Title.create_translation_table!({
                                      name: :string,
                                      short_name: :string
                                    },
                                    migrate_data: true)
  end

  def down
    Title.drop_translation_table! migrate_data: true
  end
end
