class ChangeEnumTypesForModels < ActiveRecord::Migration[5.2]
  def up
    change_column :titles,       :kind,   :string, default: Title::ESPORTS
    change_column :event_scopes, :kind,   :string, default: EventScope::TOURNAMENT
    change_column :odds,         :status, :string
    change_column :events,       :status, :string, default: Event::NOT_STARTED

    change_column :verification_documents, :status, :string
    change_column :verification_documents, :kind,   :string

    change_column :labels, :kind, :string, default: Label::CUSTOMER
  end

  def down

  end
end
