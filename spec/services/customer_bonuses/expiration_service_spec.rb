describe CustomerBonuses::ExpirationService do
  let(:customer_bonus) { create(:customer_bonus) }
  let(:expiration_reason) { CustomerBonus.expiration_reasons.keys.first }

  describe '.call' do
    let(:subject) { described_class.call(customer_bonus, expiration_reason) }

    it 'returns customer bonus with provided expiration reason' do
      expect(subject.expiration_reason).to eq(expiration_reason)
    end

    it 'removes customer bonus' do
      expect(subject.deleted_at).not_to be_nil
    end
  end
end
