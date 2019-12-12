class AddSettlementInitiatorToBetLegs < ActiveRecord::Migration[5.2]
  def change
    add_reference :bet_legs,
                  :settlement_initiator,
                  foreign_key: { to_table: :users }
  end
end
