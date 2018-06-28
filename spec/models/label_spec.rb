describe Label do
  it { should have_and_belong_to_many(:customers) }

  it { should validate_presence_of(:name) }

  it { should act_as_paranoid }
end
