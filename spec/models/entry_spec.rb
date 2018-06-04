describe Entry, type: :model do
  it { is_expected.to define_enum_for :kind }

  it { should belong_to(:wallet) }
  it { should have_many(:balance_entries) }

  it { should validate_presence_of(:kind) }
  it { should validate_presence_of(:amount) }
end
