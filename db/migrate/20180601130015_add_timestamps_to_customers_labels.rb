class AddTimestampsToCustomersLabels < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :customers_labels, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
