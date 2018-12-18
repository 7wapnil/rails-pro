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

  def down
    remove_string_column
    add_integer_column
  end

  private

  def remove_string_column # rubocop:disable Metrics/MethodLength
    remove_column :balances,               :kind
    remove_column :bets,                   :settlement_status
    remove_column :bets,                   :status
    remove_column :bonuses,                :kind
    remove_column :customers,              :account_kind
    remove_column :customers,              :gender
    remove_column :customers,              :lock_reason
    remove_column :customer_bonuses,       :kind
    remove_column :entries,                :kind
    remove_column :entry_currency_rules,   :kind
    remove_column :entry_requests,         :kind
    remove_column :entry_requests,         :mode
    remove_column :entry_requests,         :status
    remove_column :events,                 :status
    remove_column :event_scopes,           :kind
    remove_column :labels,                 :kind
    remove_column :markets,                :status
    remove_column :odds,                   :status
    remove_column :titles,                 :kind
    remove_column :verification_documents, :kind
    remove_column :verification_documents, :status
  end

  def add_integer_column # rubocop:disable Metrics/MethodLength
    add_column :balances,               :kind,              :integer, default: 0
    add_column :bets,                   :settlement_status, :integer, default: 0
    add_column :bets,                   :status,            :integer, default: 0
    add_column :bonuses,                :kind,              :integer, default: 0
    add_column :customers,              :account_kind,      :integer, default: 0
    add_column :customers,              :gender,            :integer, default: 0
    add_column :customers,              :lock_reason,       :integer, default: 0
    add_column :customer_bonuses,       :kind,              :integer, default: 0
    add_column :entries,                :kind,              :integer, default: 0
    add_column :entry_currency_rules,   :kind,              :integer, default: 0
    add_column :entry_requests,         :kind,              :integer, default: 0
    add_column :entry_requests,         :mode,              :integer, default: 0
    add_column :entry_requests,         :status,            :integer, default: 0
    add_column :events,                 :status,            :integer, default: 0
    add_column :event_scopes,           :kind,              :integer, default: 0
    add_column :labels,                 :kind,              :integer, default: 0
    add_column :markets,                :status,            :integer, default: 0
    add_column :odds,                   :status,            :integer, default: 0
    add_column :titles,                 :kind,              :integer, default: 0
    add_column :verification_documents, :kind,              :integer, default: 0
    add_column :verification_documents, :status,            :integer, default: 0
  end
end
