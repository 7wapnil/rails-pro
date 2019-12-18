# Create customer, primary currency, wallet, odd, bet relations
# Keyword to rebuild relations: ':bet'
# e.g. 'let(:bet) { voided_bet }'
# By default 'bet #=> placed_bet'
# Additional relation such a placement/winning entry require extra call
# e.g. 'before { winning_entry }'
shared_context 'manual settlement' do
  let(:wallet_amount) { 10_000 }
  let(:wallet_real_balance) { 9_000 }
  let(:wallet_bonus_balance) { 1_000 }
  let(:bet_ratio) { 0.82 }
  let(:bet_amount) { 200 }

  let(:customer) { create(:customer) }
  let(:customer_bonus) { create(:customer_bonus, customer: customer) }
  let(:currency) { create(:currency, :primary) }
  let!(:wallet) do
    create(:wallet, currency: currency,
                    customer: customer,
                    amount: wallet_amount,
                    real_money_balance: wallet_real_balance,
                    bonus_balance: wallet_bonus_balance)
  end
  let!(:customer_bonus) do
    create(:customer_bonus, customer: customer,
                            wallet: wallet,
                            status: CustomerBonus::ACTIVE,
                            rollover_balance: wallet_amount,
                            min_odds_per_bet: 1)
  end
  let(:odd) { create(:odd) }

  let(:placement_entry) do
    create(:entry, :bet, amount: -bet_amount,
                         real_money_amount: -bet_amount * bet_ratio,
                         bonus_amount: -bet_amount * (1 - bet_ratio),
                         **base_entry_params)
  end
  let(:winning_entry) do
    create(:entry, :win, amount: win_amount,
                         real_money_amount: win_real_money_amount,
                         bonus_amount: win_bonus_amount,
                         **base_entry_params)
  end
  let(:base_entry_params) do
    {
      currency: currency,
      wallet: wallet,
      origin: bet,
      customer: customer
    }
  end
  let(:win_amount) { bet_amount * odd.value }
  let(:win_real_money_amount) { bet_amount * bet_ratio * odd.value }
  let(:win_bonus_amount) { bet_amount * (1 - bet_ratio) * odd.value }

  let(:base_bet_params) do
    {
      currency: currency,
      customer: customer,
      customer_bonus: customer_bonus,
      counted_towards_rollover: counted_towards_rollover,
      amount: bet_amount
    }
  end
  let(:counted_towards_rollover) { false }
  let(:placed_bet) { create(:bet, :accepted, **base_bet_params) }
  let(:rejected_bet) { create(:bet, :rejected, **base_bet_params) }
  let(:settled_bet) { create(:bet, :settled, **base_bet_params) }
  let(:voided_bet) { create(:bet, :settled, :void, **base_bet_params) }
  let(:won_bet) do
    create(:bet, :settled, **base_bet_params,
                           status: StateMachines::BetStateMachine::SETTLED,
                           settlement_status: Bet::WON)
  end

  let(:bet) { placed_bet }
end
