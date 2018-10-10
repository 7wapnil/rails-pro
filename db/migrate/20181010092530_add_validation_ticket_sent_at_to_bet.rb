class AddValidationTicketSentAtToBet < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :validation_ticket_sent_at, :timestamp
  end
end
