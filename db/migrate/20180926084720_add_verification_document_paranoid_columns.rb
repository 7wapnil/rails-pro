class AddVerificationDocumentParanoidColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :verification_documents, :deleted_at, :datetime
    add_index :verification_documents, :deleted_at
  end
end
