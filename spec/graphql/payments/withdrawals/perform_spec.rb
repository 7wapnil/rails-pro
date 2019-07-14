# frozen_string_literal: true

describe GraphQL, '#withdraw' do
  let(:auth_customer) { create(:customer) }
  let(:amount) { Faker::Number.decimal(2, 2).to_d }
  let(:payment_method) { ::Payments::Methods::CREDIT_CARD }

  let(:details) do
    {
      holder_name: Faker::Lorem.characters(25),
      last_four_digits: '1234'
    }
  end
  let(:successful_deposit) { create(:deposit, :credit_card, details: details) }
  let!(:successful_deposit_entry_request) do
    create(:entry_request, :deposit, :succeeded, :with_entry,
           mode: ::Payments::Methods::CREDIT_CARD,
           origin: successful_deposit,
           customer: auth_customer)
  end

  let(:payload) do
    [
      { code: 'holder_name', value: details[:holder_name] },
      { code: 'last_four_digits', value: details[:last_four_digits] }
    ]
  end
  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:currency_code) { currency.code }
  let(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency)
  end
  let!(:balance) { create(:balance, :real_money, wallet: wallet) }
  let(:password) { 'iamverysecure' }

  let(:query) do
    %(mutation withdraw($input: WithdrawInput) {
        withdraw(input: $input)
      })
  end
  let(:context) { { current_customer: auth_customer } }
  let(:variables) do
    {
      input: {
        password: password,
        amount: amount,
        currencyCode: currency_code,
        paymentMethod: payment_method,
        paymentDetails: payload
      }
    }
  end
  let(:response) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  context 'when successfully' do
    before do
      allow(EntryRequests::WithdrawalWorker).to receive(:perform_async)
    end

    it 'returns true on success' do
      expect(response['data']['withdraw']).to be_truthy
    end

    it 'don\'t return error message' do
      expect(response['errors']).to be_nil
    end

    it 'passes withdrawal request to WithdrawalWorker' do
      response

      expect(EntryRequests::WithdrawalWorker)
        .to have_received(:perform_async)
        .with(EntryRequest.first.id)
    end
  end

  context 'errors' do
    context 'password' do
      let(:password) { 'wrong-password' }

      it 'returns invalid password error' do
        error = response['errors'].detect { |e| e['path'][0] == 'withdraw' }
        expect(error).not_to be_nil
      end
    end

    context 'wallet' do
      let(:currency_code) { 'allo' }

      it 'returns wrong wallet error' do
        expect(response['errors']).not_to be_nil
      end
    end

    context 'verification' do
      before do
        allow(EntryRequests::WithdrawalWorker).to receive(:perform_async)
      end

      let(:auth_customer) { create(:customer, verified: false) }

      it 'returns a customer verification error' do
        expect(response['errors']).not_to be_nil
      end

      it 'does not call the withdrawal worker' do
        response

        expect(EntryRequests::WithdrawalWorker)
          .not_to have_received(:perform_async)
      end
    end
  end
end
