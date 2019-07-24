# frozen_string_literal: true

describe EntryRequests::BackofficeEntryRequestService do
  let(:customer) { create(:customer) }
  let(:initiator) { create(:user) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let(:wallet) { customer.create_wallet(amount: 1000, currency: currency) }
  let!(:balance) { wallet.create_real_money_balance(amount: 1000) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:base_params) do
    {
      customer_id: customer.id,
      amount: 10,
      currency_id: currency.id,
      kind: EntryRequest::DEPOSIT,
      mode: EntryRequest::CREDIT_CARD,
      comment: 'comment',
      initiator: initiator
    }
  end

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  describe '#submit' do
    it 'returns created entry' do
      expect(described_class.call(base_params)).to be_instance_of(EntryRequest)
    end

    context 'trigger deposit creation flow' do
      it 'calls EntryRequests::DepositService' do
        expect(EntryRequests::DepositWorker).to receive(:perform_async)

        described_class.call(base_params)
      end

      it 'do not passes entry request to EntryRequestProcessingWorker' do
        expect(EntryRequestProcessingWorker).not_to receive(:perform_async)

        described_class.call(base_params)
      end
    end

    context 'withdrawal cancel creation flow' do
      let(:entry_params) do
        base_params.merge(
          kind: EntryRequest::WITHDRAW,
          mode: EntryRequest::SIMULATED
        )
      end

      it 'raise EntryRequests::ValidationError' do
        expect { described_class.call(entry_params) }
          .to raise_error(EntryRequests::ValidationError)
      end
    end

    context 'withdrawal success creation flow' do
      let(:entry_params) do
        base_params.merge(kind: EntryRequest::WITHDRAW)
      end

      it 'passes entry request to EntryRequestProcessingWorker' do
        allow(EntryRequest).to receive(:new).and_return(entry_request)

        expect(EntryRequestProcessingWorker)
          .to receive(:perform_async).with(entry_request.id)

        described_class.call(entry_params)
      end
    end
  end
end
