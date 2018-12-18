class ChangeEnumTypesForModels < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength
    change_column :balances,               :kind,              :string
    change_column :bets,                   :settlement_status, :string
    change_column :bets,                   :status,            :string
    change_column :bonuses,                :kind,              :string
    change_column :customers,              :account_kind,      :string
    change_column :customers,              :gender,            :string
    change_column :customers,              :lock_reason,       :string
    change_column :customer_bonuses,       :kind,              :string
    change_column :entries,                :kind,              :string
    change_column :entry_currency_rules,   :kind,              :string
    change_column :entry_requests,         :kind,              :string
    change_column :entry_requests,         :mode,              :string
    change_column :entry_requests,         :status,            :string
    change_column :events,                 :status,            :string
    change_column :event_scopes,           :kind,              :string
    change_column :labels,                 :kind,              :string
    change_column :markets,                :status,            :string
    change_column :odds,                   :status,            :string
    change_column :titles,                 :kind,              :string
    change_column :verification_documents, :kind,              :string
    change_column :verification_documents, :status,            :string
  end

  def down # rubocop:disable Metrics/MethodLength
    change_column :balances,               :kind,              :integer
    change_column :bets,                   :settlement_status, :integer
    change_column :bets,                   :status,            :integer
    change_column :bonuses,                :kind,              :integer
    change_column :customers,              :account_kind,      :integer
    change_column :customers,              :gender,            :integer
    change_column :customers,              :lock_reason,       :integer
    change_column :customer_bonuses,       :kind,              :integer
    change_column :entries,                :kind,              :integer
    change_column :entry_currency_rules,   :kind,              :integer
    change_column :entry_requests,         :kind,              :integer
    change_column :entry_requests,         :mode,              :integer
    change_column :entry_requests,         :status,            :integer
    change_column :events,                 :status,            :integer
    change_column :event_scopes,           :kind,              :integer
    change_column :labels,                 :kind,              :integer
    change_column :markets,                :status,            :integer
    change_column :odds,                   :status,            :integer
    change_column :titles,                 :kind,              :integer
    change_column :verification_documents, :kind,              :integer
    change_column :verification_documents, :status,            :integer
  end
end
