describe EventScope, type: :model do
  it { should belong_to(:discipline) }

  it { should validate_presence_of(:name) }

  it { should define_enum_for(:kind) }
end
