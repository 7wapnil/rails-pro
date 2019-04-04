describe EntryRequest do
  subject(:entry_request) { described_class.new }

  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:currency) }
  it { is_expected.to belong_to(:initiator) }
  it { is_expected.to belong_to(:origin) }
  it { is_expected.to have_many(:entries) }
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to respond_to(:external_id) }

  context 'user initiated' do
    before { entry_request.initiator = build(:user) }

    it 'validates comment if origin is user' do
      expect(entry_request).to validate_presence_of(:comment)
    end
  end

  context 'customer initiated' do
    before { entry_request.initiator = build(:customer) }

    it 'skips comment validation if origin is customer' do
      expect(entry_request).not_to validate_presence_of(:comment)
    end
  end

  context '#adjust_amount_value' do
    EntryKinds::DEBIT_KINDS.each do |kind, _i|
      it "assigns positive amount on #{kind} kinds" do
        entry_request.kind = kind
        entry_request.amount = -100

        entry_request.send(:adjust_amount_value)

        expect(entry_request.amount).to eq(100)
      end
    end

    EntryKinds::CREDIT_KINDS.each do |kind, _i|
      it "assigns negative amount on #{kind} kinds" do
        entry_request.kind = kind
        entry_request.amount = 100

        entry_request.send(:adjust_amount_value)

        expect(entry_request.amount).to eq(-100)
      end
    end
  end
end
