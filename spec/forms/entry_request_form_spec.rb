# frozen_string_literal: true

describe EntryRequestForm do
  let(:customer) { create(:customer) }
  let(:initiator) { create(:user) }
  let!(:currency) { create(:currency, :primary, code: 'EUR', name: 'Euro') }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:base_params) do
    {
      customer_id: customer.id,
      amount: 10,
      currency_id: currency.id,
      kind: EntryRequest::DEPOSIT,
      mode: EntryRequest::SIMULATED,
      comment: 'comment',
      initiator: initiator
    }
  end

  let(:form) { described_class.new(base_params) }

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  describe '#submit' do
    it 'returns created entry' do
      expect(form.submit).to be_instance_of(EntryRequest)
    end

    context 'trigger deposit creation flow' do
      let(:form) { described_class.new(base_params) }

      it 'calls EntryRequests::DepositService' do
        expect(EntryRequests::DepositWorker).to receive(:perform_async)

        form.submit
      end

      it 'do not passes entry request to EntryRequestProcessingWorker' do
        expect(EntryRequestProcessingWorker).not_to receive(:perform_async)

        form.submit
      end
    end

    context 'withdrawal creation flow' do
      let(:entry_params) do
        base_params.merge(kind: EntryRequest::WITHDRAW)
      end

      let(:form) { described_class.new(entry_params) }

      it 'does not call EntryRequests::DepositService' do
        expect(EntryRequests::DepositWorker).not_to receive(:perform_async)

        form.submit
      end

      it 'passes entry request to EntryRequestProcessingWorker' do
        allow(EntryRequest).to receive(:new).and_return(entry_request)

        expect(EntryRequestProcessingWorker).to receive(:perform_async)
          .with(entry_request.id)

        form.submit
      end
    end
  end

  describe '#errors' do
    let(:form) { described_class.new(base_params) }

    it 'returns validation errors' do
      base_params[:mode] = EntryRequest::CASHIER
      entry_request.initiator = nil
      entry_request.valid?

      allow(EntryRequest).to receive(:new).and_return(entry_request)

      form.submit

      expect(form.errors).to eq(entry_request.errors.full_messages)
    end
  end
end
