describe EventScope, type: :model do
  it { should belong_to(:discipline) }

  it { should define_enum_for(:kind) }

  it { should validate_presence_of(:name) }
end
