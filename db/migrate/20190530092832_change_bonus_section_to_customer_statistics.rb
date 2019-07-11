# frozen_string_literal: true

class ChangeBonusSectionToCustomerStatistics < ActiveRecord::Migration[5.2]
  def up
    remove_column :customer_statistics, :theoretical_bonus_cost
    remove_column :customer_statistics, :potential_bonus_cost
    remove_column :customer_statistics, :actual_bonus_cost

    add_column :customer_statistics, :total_bonus_awarded, :decimal,
               default: 0.0, precision: 8, scale: 2
    add_column :customer_statistics, :total_bonus_completed, :decimal,
               default: 0.0, precision: 8, scale: 2
  end

  def down
    add_column :customer_statistics, :theoretical_bonus_cost, :decimal,
               default: 0.0, precision: 8, scale: 2
    add_column :customer_statistics, :potential_bonus_cost, :decimal,
               default: 0.0, precision: 8, scale: 2
    add_column :customer_statistics, :actual_bonus_cost, :decimal,
               default: 0.0, precision: 8, scale: 2

    remove_column :customer_statistic, :total_bonus_awarded
    remove_column :customer_statistic, :total_bonus_completed
  end
end
