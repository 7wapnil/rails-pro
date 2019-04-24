describe GraphQL, '#requestPasswordReset' do
  let(:variables) { { email: Faker::Internet.email } }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($email: String!) {
        requestPasswordReset(email: $email)
      })
  end

  before do
    allow(Account::SendPasswordResetService).to receive(:call)
  end

  it 'calls Account::SendPasswordResetService' do
    result[:data]

    expect(Account::SendPasswordResetService).to have_received(:call)
  end
end
