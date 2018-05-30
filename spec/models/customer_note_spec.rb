describe CustomerNote, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:customer) }

  it { should validate_presence_of(:content) }
end
