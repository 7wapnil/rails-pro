describe BonusExpiration::Expired do
  let(:expiration_reason) { CustomerBonus.expiration_reasons.keys.first }
  let(:another_expiration_reason) { CustomerBonus.expiration_reasons.keys.last }

  describe '.call' do
    context 'raise errors' do
      subject(:service_call) { described_class.call(customer_bonus) }

      let(:customer_bonus) { create(:customer_bonus) }

      it 'raise argument error when pass without reason' do
        expect { service_call }.to raise_error(ArgumentError)
      end
    end

    context 'with active customer bonus' do
      let(:customer_bonus) { create(:customer_bonus) }

      before do
        described_class.call(customer_bonus, reason: expiration_reason)
      end

      it 'returns customer bonus with provided expiration reason' do
        expect(customer_bonus.expiration_reason).to eq(expiration_reason)
      end

      it 'removes customer bonus' do
        expect(customer_bonus.deleted_at).not_to be_nil
      end
    end

    context 'with already processed bonus' do
      let(:expiration_time) { Time.zone.now }
      let(:customer_bonus) do
        create(:customer_bonus,
               deleted_at: expiration_time,
               expiration_reason: expiration_reason)
      end

      before do
        described_class.call(customer_bonus, reason: another_expiration_reason)
        Timecop.freeze(expiration_time + 1.minute)
      end

      it 'does not override expired bonus reason' do
        expect(customer_bonus.expiration_reason).to eq(expiration_reason)
      end

      it 'does not override original expiration date' do
        expect(customer_bonus.deleted_at).to eq(expiration_time)
      end
    end
  end
end
