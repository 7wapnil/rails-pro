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
               status: EntryRequest::SUCCEEDED,
               kind: EntryRequest::DEPOSIT)

        create(:entry_request,
               customer: auth_customer,
               mode: EntryRequest::CREDIT_CARD,
               status: EntryRequest::PENDING,
               kind: EntryRequest::DEPOSIT)

        create(:entry_request,
               customer: auth_customer,
               status: EntryRequest::SUCCEEDED,
               kind: EntryRequest::WITHDRAW)

        create(:entry_request,
               customer: auth_customer,
               status: EntryRequest::SUCCEEDED,
               kind: EntryRequest::BET)
      end

      it 'returns only succeeded deposit-based payment methods' do
        expect(result['data']['paymentMethods'].length).to eq 1
      end

      it 'returns list of auth customer payment methods' do
        expect(result['data']['paymentMethods'].first['name'])
          .to eq(EntryRequest::CREDIT_CARD)
      end

      it 'has all required fields' do
        expect(result['data']['paymentMethods'].first)
          .to include('name' => EntryRequest::CREDIT_CARD,
                      'code' => EntryRequest::CREDIT_CARD,
                      'type' => Currency::FIAT)
      end
    end

    context 'when there is no payment method' do
      it 'returns empty list of auth customer payment methods' do
        expect(result['data']['paymentMethods']).to be_empty
      end
    end
  end
end
