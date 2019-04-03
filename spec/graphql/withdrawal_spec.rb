describe GraphQL, '#withdraw' do
  let(:auth_customer) { create(:customer) }
  let(:amount) { Faker::Number.decimal(2, 2).to_d }
  let(:payment_method) { EntryRequest::CREDIT_CARD }
  let(:payload) do
    SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[payment_method]&.map do |row|
      { code: row[:code].to_s, value: Faker::Lorem.word }
    end
  end
  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency)
  end
  let(:wallet_id) do
    wallet.id.to_s
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
        walletId: wallet_id,
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

    it 'returns true ob success' do
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
        error = response['errors'].detect { |e| e['path'][0] == :password }
        expect(error).not_to be_nil
      end
    end

    context 'wallet' do
      let(:wallet_id) { '1010101' }

      it 'returns wrong wallet error' do
        expect(response['errors']).not_to be_nil
      end
    end
  end
end
