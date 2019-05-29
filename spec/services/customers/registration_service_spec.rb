describe Customers::RegistrationService do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:valid_input) do
    { username: 'test',
      email: 'test@email.com',
      first_name: 'Test',
      last_name: 'User',
      date_of_birth: '01-01-1999',
      phone: '37258383943',
      password: '123456',
      password_confirmation: '123456',
      currency: 'EUR' }
  end

  before { create(:currency, code: 'EUR') }

  it 'raises error on invalid customer data' do
    expect { described_class.call({}) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'returns customer on successful registration' do
    customer = described_class.call(valid_input)
    expect(customer).to be_a(Customer)
  end

  it 'logs audit event on registration' do
    allow(Audit::Service).to receive(:call)
    described_class.call(valid_input)
    expect(Audit::Service).to have_received(:call)
  end

  it 'sends activation email' do
    subject = described_class.new(valid_input)
    allow(subject).to receive(:send_email_verification_email)
    subject.call
    expect(subject).to have_received(:send_email_verification_email)
  end

  it 'creates customer related wallet' do
    subject = described_class.new(valid_input)
    allow(subject).to receive(:send_email_verification_email)
    expect(subject.call.wallets).not_to be_empty
  end
end
