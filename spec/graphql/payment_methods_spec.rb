# frozen_string_literal: true

describe GraphQL, '#payment_methods' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:query) do
    %({ paymentMethods { name code type fields { name code type } } })
  end
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    context 'when payment method exist' do
      before do
        create(:entry_request,
               customer: auth_customer,
               mode: EntryRequest::CREDIT_CARD,
               status: EntryRequest::SUCCEEDED)
      end

      it 'returns list of auth customer payment methods' do
        expect(result['data']['paymentMethods'].first['name'])
          .to eq(EntryRequest::CREDIT_CARD)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'has all required fields' do
        expect(result['data']['paymentMethods'].first).to have_key('name')
        expect(result['data']['paymentMethods'].first).to have_key('code')
        expect(result['data']['paymentMethods'].first).to have_key('type')

        expect(result['data']['paymentMethods'].first['fields'].first)
          .to have_key('name')
        expect(result['data']['paymentMethods'].first['fields'].first)
          .to have_key('code')
        expect(result['data']['paymentMethods'].first['fields'].first)
          .to have_key('type')
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'when there is no payment method' do
      it 'returns empty list of auth customer payment methods' do
        expect(result['data']['paymentMethods']).to be_empty
      end
    end
  end
end
