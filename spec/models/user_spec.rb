describe User do
  it { is_expected.to have_many(:entry_requests) }

  it_behaves_like 'LoginAttemptable'
end
