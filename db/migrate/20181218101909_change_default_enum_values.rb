class ChangeDefaultEnumValues < ActiveRecord::Migration[5.2]
  def up
    change_column_default :titles,         :kind,         Title::ESPORTS
    change_column_default :event_scopes,   :kind,         EventScope::TOURNAMENT
    change_column_default :events,         :status,       Event::NOT_STARTED
    change_column_default :labels,         :kind,         Label::CUSTOMER
    change_column_default :entry_requests, :status,       EntryRequest::PENDING
    change_column_default :customers,      :account_kind, Customer::REGULAR
  end

  def down; end
end
