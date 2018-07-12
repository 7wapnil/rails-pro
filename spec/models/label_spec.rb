describe Label do
  it_should_behave_like 'audit model', factory: :label

  it { should have_and_belong_to_many(:customers) }

  it { should validate_presence_of(:name) }

  it { should act_as_paranoid }
end
