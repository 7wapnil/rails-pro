class ChangeEnumTypesForModels < ActiveRecord::Migration[5.2]
  def up
    change_column :titles,       :kind,   :string, default: Title::ESPORTS
    change_column :event_scopes, :kind,   :string, default: EventScope::TOURNAMENT
    change_column :events,       :status, :string, default: Event::NOT_STARTED
    change_column :odds,         :status, :string

    change_column :verification_documents, :status, :string
    change_column :verification_documents, :kind,   :string

    change_column :labels, :kind, :string, default: Label::CUSTOMER

    change_column :entry_requests, :status, :string, default: EntryRequest::PENDING
    change_column :entry_requests, :mode,   :string

    change_column :balances, :kind, :string

    change_column :customers, :gender,       :string
    change_column :customers, :lock_reason,  :string
    change_column :customers, :account_kind, :string, default: Customer::REGULAR

    change_column :markets, :status, :string
  end

  def down

  end
end
