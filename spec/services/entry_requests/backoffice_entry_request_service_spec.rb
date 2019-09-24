# frozen_string_literal: true

describe EntryRequests::BackofficeEntryRequestService do
  let(:customer) { create(:customer) }
  let(:initiator) { create(:user) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let!(:wallet) do
    customer.create_wallet(
      amount: 1000,
      real_money_balance: 1000,
      currency: currency
    )
  end
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:base_params) do
    {
      customer: customer,
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
    allow(Audit::Service).to receive(:call)
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
          amount: 0
        )
      end

      it 'raise EntryRequests::ValidationError' do
        expect { described_class.call(entry_params) }
          .to raise_error(EntryRequests::ValidationError)
      end

      it 'does not create audit log' do
        described_class.call(entry_params)
      rescue EntryRequests::ValidationError
        expect(Audit::Service).not_to have_received(:call)
      end
    end

    context 'withdrawal success creation flow' do
      let(:entry_params) do
        base_params.merge(kind: EntryRequest::WITHDRAW)
      end

      before do
        allow(EntryRequest).to receive(:new).and_return(entry_request)
      end

      it 'passes entry request to EntryRequestProcessingWorker' do
        expect(EntryRequestProcessingWorker)
          .to receive(:perform_async).with(entry_request.id)

        described_class.call(entry_params)
      end

      it 'creates audit log' do
        described_class.call(entry_params)

        expect(Audit::Service)
          .to have_received(:call)
          .with(event: :entry_request_created,
                user: initiator,
                customer: customer,
                context: entry_request)
      end
    end
  end
end
