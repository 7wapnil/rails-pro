describe GraphQL, '#deposit_bonus' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { { amount: amount, code: code } }
  let(:amount) { 100.0 }

  let(:query) do
    %(mutation deposit_bonus($amount: Float!, $code: String!) {
      deposit_bonus(amount: $amount, code: $code) {
        real_money
        bonus
      }
    })
  end

  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'when bonus not found' do
    let(:code) { 'haha_not_found' }
    let(:error_message) { result['errors'][0]['message'] }

    it 'returns an error on a missing bonus code' do
      expect(error_message).to start_with('Couldn\'t find Bonus')
    end
  end

  describe 'basic query with an existing bonus' do
    let!(:bonus) { create(:bonus) }
    let(:code) { bonus.code }
    let(:deposit_bonus) { result['data']['deposit_bonus'] }

    describe 'when amount is too low' do
      let(:amount) { bonus.min_deposit - 1.0 }

      it 'returns zero bonus' do
        expect(deposit_bonus['bonus']).to be_zero
      end
    end

    describe 'when amount is just right' do
      let(:amount) { bonus.min_deposit + 1.0 }

      it 'returns real money amount multiplied by bonus multiplier' do
        expect(deposit_bonus['bonus'])
          .to eq(amount * (bonus.percentage / 100.0))
      end
    end

    describe 'when amount is too high' do
      let(:amount) { bonus.max_deposit_match + 1.0 }

      it 'returns max amount allowed by the bonus' do
        expect(deposit_bonus['bonus'])
          .to eq(bonus.max_deposit_match * (bonus.percentage / 100.0))
      end
    end

    it 'returns the original amount along with bonus value' do
      expect(deposit_bonus['real_money']).to eq(amount)
    end
  end

  describe 'when bonus is expired' do
    let(:bonus) { create(:bonus, expires_at: 1.day.ago) }
    let(:code) { bonus.code }
    let(:error_message) { result['errors'][0]['message'] }

    it 'returns an error on a missing bonus code' do
      expect(error_message).to start_with('Couldn\'t find Bonus')
    end
  end
end
