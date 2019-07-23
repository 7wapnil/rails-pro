describe GraphQL, '#deposit_bonus' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { { amount: amount, code: code } }
  let(:amount) { 100.0 }

  let(:query) do
    %(mutation depositBonus($amount: Float!, $code: String!) {
      depositBonus(amount: $amount, code: $code) {
        realMoney
        bonus
      }
    })
  end

  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end
  let(:error_message) { result['errors'][0]['message'] }

  describe 'when bonus not found' do
    let(:code) { 'haha_not_found' }

    it 'returns an error on a missing bonus code' do
      expect(error_message).to eq('No bonus found')
    end
  end

  describe 'basic query with an existing bonus' do
    let!(:bonus) { create(:bonus) }
    let(:code) { bonus.code }
    let(:deposit_bonus) { result['data']['depositBonus'] }

    describe 'when amount is too low' do
      let(:amount) { bonus.min_deposit - 1.0 }

      it 'returns error message' do
        expect(error_message).to eq(
          I18n.t('errors.messages.bonus_minimum_requirements_failed')
        )
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
      expect(deposit_bonus['realMoney']).to eq(amount)
    end
  end

  describe 'when bonus is expired' do
    let(:bonus) { create(:bonus, expires_at: 1.day.ago) }
    let(:code) { bonus.code }

    it 'returns an error on a missing bonus code' do
      expect(error_message).to eq('No bonus found')
    end
  end

  describe 'code case' do
    let!(:bonus) { create(:bonus, code: 'AbC') }
    let(:code) { 'aBc' }

    it 'is case insensitive to code' do
      expect(result['errors']).to be_blank
    end
  end

  describe 'when customer already has active bonus' do
    let(:bonus) { create(:bonus) }
    let(:other_bonus) { create(:bonus) }
    let(:code) { bonus.code }
    let!(:customer_bonus) do
      create(
        :customer_bonus,
        original_bonus: other_bonus,
        customer: auth_customer,
        status: 'active'
      )
    end

    it 'returns an error on an already activated bonus' do
      expect(error_message).to eq(
        I18n.t('errors.messages.customer_has_active_bonus')
      )
    end
  end

  describe 'when bonus is non-repeatable' do
    let(:bonus) { create(:bonus, repeatable: false) }
    let(:code) { bonus.code }
    let!(:customer_bonus) do
      create(
        :customer_bonus,
        original_bonus: bonus,
        customer: auth_customer,
        status: 'completed'
      )
    end

    it 'returns an error on repeated bonus activation' do
      expect(error_message).to eq(
        I18n.t('errors.messages.repeated_bonus_activation')
      )
    end
  end
end
