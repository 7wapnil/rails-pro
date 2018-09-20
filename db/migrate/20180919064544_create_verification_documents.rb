class CreateVerificationDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :verification_documents do |t|
      t.references :customer, foreign_key: true
      t.integer :kind
      t.integer :status

      t.timestamps
    end
  end
end
