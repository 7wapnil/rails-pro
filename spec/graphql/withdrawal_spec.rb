describe GraphQL, '#withdraw' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { { amount: 10.0, walletId: wallet.id } }
  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:wallet) do
    create(:wallet, :brick, customer: auth_customer, currency: currency)
  end
  let!(:balance) { create(:balance, :real_money, wallet: wallet) }

  let(:query) do
    %(mutation withdraw($amount: Float!, $walletId: ID!) {
        withdraw(amount: $amount, walletId: $walletId) {
          error_messages
          id
          status
        }
      })
  end
  let(:response) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)['data']['withdraw']
  end

  context 'when successfully' do
    let(:variables) { { amount: 10.0, walletId: wallet.id.to_s } }
    let(:entry_request) { create(:entry_request) }

    before do
      allow(EntryRequests::Factories::Withdrawal)
        .to receive(:call) { entry_request }

      allow(EntryRequests::WithdrawalWorker)
        .to receive(:perform_async)
        .and_call_original
    end

    it 'passes withdrawal request to WithdrawalWorker' do
      response

      expect(EntryRequests::WithdrawalWorker)
        .to have_received(:perform_async)
        .with(entry_request.id)
    end

    it "don't return error message" do
      expect(response['error_messages']).to be_nil
    end
    it 'returns entry request status' do
      expect(response['status']).to eq(entry_request.status)
    end

    it 'returns entry request id' do
      expect(response['id'].to_i).to eq(entry_request.id)
    end
  end

  context 'with errors' do
    let(:error_class) { Withdrawals::WithdrawalError }
    let(:error_msg) { Faker::Lorem.sentence }

    before do
      allow(EntryRequests::Factories::Withdrawal).to receive(:call)
        .and_raise(error_class, error_msg)
    end

    it 'returns array of error messages' do
      expect(response['error_messages']).to eq([error_msg])
    end
  end
end
