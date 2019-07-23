# frozen_string_literal: true

describe Deposits::VerifyDepositAttempt do
  let(:customer) { instance_double(Customer) }
  let(:max_attempts) { Deposits::VerifyDepositAttempt::MAX_DEPOSIT_ATTEMPTS }
  let(:service_call) { described_class.call(customer) }

  it 'return false when attempts exceeded' do
    allow(customer).to receive(:deposit_attempts).and_return(max_attempts + 1)

    expect(service_call).to be_falsey
  end

  it 'return true when count of attempts is not greater than allow' do
    allow(customer).to receive(:deposit_attempts).and_return(max_attempts)

    expect(service_call).to be_truthy
  end
end
