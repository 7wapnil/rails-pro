# frozen_string_literal: true

describe Deposits::VerifyDepositAttempt do
  let(:customer) { instance_double(Customer) }
  let(:max_attempts) { Deposits::VerifyDepositAttempt::MAX_DEPOSIT_ATTEMPTS }
  let(:service_call) { described_class.call(customer) }

  it 'raises error when attempts exceeded' do
    allow(customer).to receive(:deposit_attempts).and_return(max_attempts + 1)
    msg = I18n.t('errors.messages.deposit_attempts_exceeded')

    expect { service_call }.to raise_error(Deposits::DepositAttemptError, msg)
  end

  it "don't raise error when count of attempts is not greater than allow" do
    allow(customer).to receive(:deposit_attempts).and_return(max_attempts)

    expect { service_call }.not_to raise_error
  end
end
