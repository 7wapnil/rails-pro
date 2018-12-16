describe EntryRequest do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should belong_to(:initiator) }
  it { should belong_to(:origin) }

  # it { should define_enum_for :status }
  # it { should define_enum_for :mode }
  it { should define_enum_for :kind }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:kind) }

  context 'user initiated' do
    before { subject.initiator = build(:user) }

    it 'validates comment if origin is user' do
      should validate_presence_of(:comment)
    end
  end

  context 'customer initiated' do
    before { subject.initiator = build(:customer) }

    it 'skips comment validation if origin is customer' do
      should_not validate_presence_of(:comment)
    end
  end

  context '#adjust_amount_value' do
    EntryKinds::DEBIT_KINDS.each do |kind, _i|
      it "assigns positive amount on #{kind} kinds" do
        subject.kind = kind
        subject.amount = -100

        subject.send(:adjust_amount_value)

        expect(subject.amount).to eq(100)
      end
    end

    EntryKinds::CREDIT_KINDS.each do |kind, _i|
      it "assigns negative amount on #{kind} kinds" do
        subject.kind = kind
        subject.amount = 100

        subject.send(:adjust_amount_value)

        expect(subject.amount).to eq(-100)
      end
    end
  end
end
