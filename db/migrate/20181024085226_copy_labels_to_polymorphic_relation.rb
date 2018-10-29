class CopyLabelsToPolymorphicRelation < ActiveRecord::Migration[5.2]
  def up
    sql = <<-SQL
     SELECT label_id, customer_id FROM customers_labels
    SQL
    customers_labels = ActiveRecord::Base.connection.execute(sql)
    columns = %i[label_id labelable_id labelable_type]
    values = customers_labels.map { |e| e.values + ['Customer'] }
    LabelJoin.import(columns, values)

    drop_table :customers_labels
  end

  def down # rubocop:disable Metrics/MethodLength:
    create_table :customers_labels, id: false do |t|
      t.belongs_to :customer, index: true
      t.belongs_to :label, index: true
    end
    select_ids = <<-SQL
      SELECT label_id, labelable_id
      FROM label_joins
      WHERE labelable_type = 'Customer'
    SQL

    ids = ActiveRecord::Base.connection.execute(select_ids)
    insert_value = ids.map { |id_pair| "(#{id_pair.values.join(',')})" }
    return if insert_value.empty?

    insert_customer_labels_ids = <<-SQL
      INSERT INTO customers_labels (label_id, customer_id) VALUES
      #{insert_value.join(',')}
    SQL
    ActiveRecord::Base.connection.execute(insert_customer_labels_ids)
    LabelJoin.delete_all
  end
end
