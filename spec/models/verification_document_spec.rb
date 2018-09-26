describe VerificationDocument do
  it { should belong_to(:customer) }

  it { should act_as_paranoid }
end
