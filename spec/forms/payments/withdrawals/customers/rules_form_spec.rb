describe ::Payments::Withdrawals::Customers::RulesForm, type: :model do
  subject { described_class.new(params) }

  let(:params) do
    {
      customer: customer,
      password: password
    }
  end

  let(:customer) { create(:customer) }
  let(:password) { 'iamverysecure' }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'presence' do
    it { is_expected.to validate_presence_of(:customer) }
    it { is_expected.to validate_presence_of(:password) }
  end

  context 'succeeded' do
    it 'be valid' do
      expect(subject).to be_valid
    end
  end

  context 'when invalid password' do
    let(:password) { 'iammoreverysecure' }

    it 'has error' do
      subject.validate

      expect(subject.errors).to include(:password)
    end
  end

  context 'when unverified customer' do
    let(:customer) { create(:customer, verified: false) }

    it 'has error' do
      subject.validate

      expect(subject.errors).to include(:status)
    end
  end
end
