describe BalanceCalculations::BetWithBonus do
  subject(:service_call_response) { described_class.call(bet) }

  let(:amount) { 10 }
  let(:bet) { instance_double('Bet', ratio: 0.75, amount: amount) }

  context 'with existent bonus balance and real money balance' do
    let(:calculations) { { real_money: 7.5, bonus: 2.5 } }

    it 'calculates real and bonus amount' do
      expect(service_call_response).to include(calculations)
    end
  end
end
