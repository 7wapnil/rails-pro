describe EntryRequest, type: :model do
  it { is_expected.to define_enum_for :status }
  it { should validate_presence_of(:payload) }
end
