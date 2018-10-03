class AddValidationTicketIdToBet < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :validation_ticket_id, :string
  end
end
