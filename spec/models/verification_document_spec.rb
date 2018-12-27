describe VerificationDocument do
  it { is_expected.to belong_to(:customer) }

  it { is_expected.to act_as_paranoid }
end
