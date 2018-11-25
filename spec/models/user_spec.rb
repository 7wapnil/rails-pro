describe User do
  it { should have_many(:entry_requests) }

  it_behaves_like 'LoginAttemptable'
end
