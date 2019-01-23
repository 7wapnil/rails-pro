describe Deposits::EntryRequestUrlService do
  let(:entry_request) { build(:entry_request, status: EntryRequest::INITIAL) }

  before do
    allow(Deposits::GetPaymentPageUrl).to receive(:call)
  end

  describe '.call' do
    subject(:service_call) do
      described_class.call(entry_request: entry_request)
    end

    it 'requests url from PaymentPageUrlService for initial entry request' do
      service_call
      expect(Deposits::GetPaymentPageUrl)
        .to have_received(:call)
        .with(entry_request: entry_request).once
    end

    context 'when entry request is failed' do
      let(:entry_request) do
        build(:entry_request,
              status: EntryRequest::FAILED,
              result: Faker::Lorem.sentence)
      end

      before do
        allow(Deposit::CallbackUrl).to receive(:for)
        service_call
      end

      it 'calls callback service' do
        expect(Deposit::CallbackUrl)
          .to have_received(:for)
          .with(:failed_entry_request, message: entry_request.result).once
      end
    end

    [EntryRequest::SUCCEEDED, EntryRequest::PENDING].each do |state|
      context "when #{state} entry request comes" do
        let(:entry_request) { build(:entry_request, status: state) }

        it 'raises an error' do
          expect { service_call }.to raise_error(StandardError)
        end
      end
    end
  end
end
