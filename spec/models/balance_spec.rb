describe Balance, type: :model do
  it { should belong_to(:wallet) }
  it { should have_many(:balance_entries) }
  it { is_expected.to define_enum_for :type }
end
