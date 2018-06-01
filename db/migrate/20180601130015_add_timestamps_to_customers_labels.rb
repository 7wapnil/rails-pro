class AddTimestampsToCustomersLabels < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :customers_labels
  end
end
