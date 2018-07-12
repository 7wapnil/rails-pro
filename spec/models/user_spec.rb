describe User do
  it_should_behave_like 'audit model', factory: :user

  it { should have_many(:entry_requests) }
end
