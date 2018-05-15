describe Customer, type: :model do
  it { should have_one(:address) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }

  it { should validate_uniqueness_of(:username).case_insensitive }
  it { should validate_uniqueness_of(:email).case_insensitive }
end
