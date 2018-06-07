describe EntryRequestPayload do
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule) }
  let(:payload) { build(:entry_request_payload) }

  subject { payload }

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:currency_code) }
  it { should validate_presence_of(:customer_id) }

  it { should validate_numericality_of(:amount) }

  it { should validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { should validate_inclusion_of(:currency_code).in_array(Currency.select(:code).map(&:code)) } # rubocop:disable Metrics/LineLength

  context '#customer' do
    subject { payload.customer }

    it { is_expected.to be_a Customer }

    it 'raises RecordNotFound exception' do
      payload.customer_id = 0

      expect { payload.customer }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
