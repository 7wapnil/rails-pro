describe Odd do
  it { should define_enum_for(:status) }

  it { should belong_to(:market) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:value) }
  it { should validate_presence_of(:status) }
  it { should validate_numericality_of(:value).is_greater_than(0) }
end
