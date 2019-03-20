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
      let(:payment_method) { Faker::Lorem.word }
      let(:payment_detail) { { name: 'bar', code: :bar, type: :float } }
      let(:payment_method_name) do
        I18n.t("payment_methods.#{payment_method}.title",
               default: payment_method.humanize)
      end
      let(:payment_method_note) do
        I18n.t("payment_methods.#{payment_method}.payment_note",
               default: payment_method.humanize)
      end

      before do
        withdraw_map_model = SafeCharge::Withdraw
        stub_const(
          "#{withdraw_map_model}::AVAILABLE_WITHDRAW_MODES",
          EntryRequest::CREDIT_CARD => [payment_method],
          Faker::Lorem.word => [Faker::Lorem.word]
        )
        stub_const(
          "#{withdraw_map_model}::WITHDRAW_MODE_FIELDS",
          payment_method => [payment_detail],
          Faker::Lorem.word => [Faker::Lorem.word]
        )

        create(:entry_request,
               customer: auth_customer,
               mode: EntryRequest::CREDIT_CARD,
               status: EntryRequest::SUCCEEDED,
               kind: EntryRequest::DEPOSIT)

        create(:entry_request,
               customer: auth_customer,
               status: EntryRequest::SUCCEEDED,
               kind: EntryRequest::DEPOSIT)
          .update_attribute(:mode, nil)

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

      it 'returns correct count of succeeded deposit-based payment methods' do
        expect(result['data']['paymentMethods'].length).to eq 1
      end

      it 'returns correct name for correct first payment method' do
        expect(result['data']['paymentMethods'].first['name'])
          .to eq(payment_method_name)
      end

      it 'returns correct payment method fields' do
        expect(result['data']['paymentMethods'].first['fields'])
          .to eq([payment_detail.stringify_keys.transform_values(&:to_s)])
      end

      it 'has all required fields' do
        expect(result['data']['paymentMethods'].first)
          .to include('name' => payment_method_name,
                      'code' => payment_method,
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
