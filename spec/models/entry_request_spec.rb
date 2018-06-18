describe EntryRequest do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }

  it { should define_enum_for :status }
  it { should define_enum_for :kind }
  it { should define_enum_for :origin_type }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:origin_type) }
  it { should validate_presence_of(:origin_id) }

  context 'user originated' do
    before { subject.origin_type = :user }

    it 'should validate comment if origin is user' do
      should validate_presence_of(:comment)
    end
  end

  context 'customer originated' do
    before { subject.origin_type = :customer }

    it 'should skip comment validation if origin is customer' do
      should_not validate_presence_of(:comment)
    end
  end

  it 'should return user instance if origin is user' do
    user = create(:user)
    request = build(:entry_request)
    request.origin_type = EntryRequest.origin_types[:user]
    request.origin_id = user.id

    expect(request.origin).to be_instance_of User
  end

  it 'should return customer instance if origin is customer' do
    customer = create(:customer)
    request = build(:entry_request)
    request.origin_type = EntryRequest.origin_types[:customer]
    request.origin_id = customer.id

    expect(request.origin).to be_instance_of Customer
  end
end
