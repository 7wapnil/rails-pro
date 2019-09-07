describe ::Payments::Deposits::Customers::RulesForm, type: :model do
  subject { described_class.new(params) }

  let(:params) do
    {
      amount: amount,
      wallet: wallet,
      customer: customer
    }
  end

  let(:customer) { create(:customer) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) do
    create(:wallet, :fiat, currency: currency, customer: customer)
  end
  let(:amount) { 10 }
  let(:attempts) { 5 }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'presence' do
    it { is_expected.to validate_presence_of(:customer) }
  end

  context 'succeeded' do
    it 'be valid' do
      expect(subject).to be_valid
    end
  end

  context 'when over deposit attempts' do
    let(:attempts) { 0 }
    let!(:entry_requests) do
      create_list(
        :entry_request, 6,
        kind: EntryRequest::DEPOSIT,
        status: EntryRequest::FAILED,
        customer: customer,
        currency: currency,
        created_at: Time.zone.now
      )
    end

    xit 'has error' do
      subject.validate

      expect(subject.errors).to include(:attempts)
    end
  end

  context 'when over deposit limit' do
    let!(:deposit_limit) do
      create(
        :deposit_limit,
        value: amount - 1,
        customer: customer,
        currency: currency
      )
    end

    it 'has error' do
      subject.validate

      expect(subject.errors).to include(:limit)
    end
  end
end
