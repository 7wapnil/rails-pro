describe EntryRequests::Factories::BonusConversion do
  context 'when creating bonus conversion entry request' do
    subject { service.call }

    let(:service) { described_class.new(customer_bonus: customer_bonus) }
    let(:bonus_balance) { create(:balance, :bonus) }
    let(:wallet) { create(:wallet, bonus_balance: bonus_balance) }
    let(:customer_bonus) { create(:customer_bonus, wallet: wallet, customer: wallet.customer) }

    it 'creates the entry request' do
      expect(subject).not_to be_nil 
    end

    it 'sets correct attributes' do
      expect(subject).to have_attributes({
        amount: bonus_balance.amount,
        mode: EntryRequest::INTERNAL,
        kind: EntryRequest::BONUS_CONVERSION,
        origin: customer_bonus,
        currency: wallet.currency,
        customer: wallet.customer
      })
    end
  end
end
