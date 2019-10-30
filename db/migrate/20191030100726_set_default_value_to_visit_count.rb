class SetDefaultValueToVisitCount < ActiveRecord::Migration[5.2]
  def change
    change_column_default :customers, :visit_count, from: nil, to: 0
  end
end
