describe Customer do
  it_should_behave_like 'audit model', factory: :customer

  it { should have_one(:address) }
  it { should have_many(:wallets) }
  it { should have_many(:entry_requests) }
  it { should have_and_belong_to_many(:labels) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:date_of_birth) }

  it { should validate_uniqueness_of(:username).case_insensitive }
  it { should validate_uniqueness_of(:email).case_insensitive }

  it { should act_as_paranoid }
end
