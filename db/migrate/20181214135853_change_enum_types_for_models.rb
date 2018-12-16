class ChangeEnumTypesForModels < ActiveRecord::Migration[5.2]
  def up
    change_column :titles,       :kind,   :string, default: Title::ESPORTS
    change_column :event_scopes, :kind,   :string, default: EventScope::TOURNAMENT
  end

  def down

  end
end
