# frozen_string_literal: true

describe GraphQL, '#cancelActiveBonus' do
  let(:query) { %(mutation { cancelActiveBonus }) }
  let(:context) { {} }
  let(:result) { ArcanebetSchema.execute(query, context: context) }
  let(:error_message) { result['errors'][0]['message'] }

  context 'unauthorized request' do
    it 'returns error' do
      expect(error_message).to eq('AUTH_REQUIRED')
    end
  end

  context 'authorized request' do
    let(:customer) { create(:customer, :ready_to_bet) }
    let(:context) { { current_customer: customer } }

    context 'with active bonus' do
      let(:bonus) { create(:bonus) }
      let(:wallet) { customer.wallet }
      let!(:customer_bonus) do
        create(:customer_bonus,
               wallet: wallet,
               customer: customer,
               original_bonus: bonus)
      end

      before { create(:currency, :primary) }

      it 'returns true' do
        expect(result.dig('data', 'cancelActiveBonus')).to be true
      end

      it 'cancells the active bonus' do
        expect { result }.to(
          change { customer_bonus.reload.status }.from('active').to('cancelled')
        )
      end
    end

    context 'without active bonus' do
      it 'returns error' do
        expect(error_message).to eq(
          I18n.t('errors.messages.customer_should_have_active_bonus')
        )
      end
    end
  end
end
