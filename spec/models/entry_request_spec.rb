describe EntryRequest do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should belong_to(:origin) }

  it { should define_enum_for :status }
  it { should define_enum_for :kind }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:kind) }

  context 'user originated' do
    before { subject.origin = build(:user) }

    it 'should validate comment if origin is user' do
      should validate_presence_of(:comment)
    end
  end

  context 'customer originated' do
    before { subject.origin = build(:customer) }

    it 'should skip comment validation if origin is customer' do
      should_not validate_presence_of(:comment)
    end
  end
end
