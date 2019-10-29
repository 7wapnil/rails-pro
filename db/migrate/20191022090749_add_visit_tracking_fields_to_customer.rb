class AddVisitTrackingFieldsToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :visit_count, :integer
    add_column :customers, :last_visit_at, :datetime
    add_column :customers, :last_visit_ip, :inet
    add_column :customers, :last_activity_at, :datetime
  end
end
