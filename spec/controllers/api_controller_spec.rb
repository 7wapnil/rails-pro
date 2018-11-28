describe ApiController, type: :controller do
  context '#current_customer' do
    let(:user) { create(:user) }
    let(:customer) { create(:customer) }
    subject { described_class.new }

    it 'returns impersonated customer' do
      token = JwtService.encode(impersonated_by: user.id, id: customer.id)
      auth = "Bearer #{token}"
      request = { headers: { 'Authorization' => auth } }
      allow(subject).to receive(:request).and_return(OpenStruct.new(request))
      customer = subject.current_customer

      expect(customer).to be_instance_of(ImpersonatedCustomerDecorator)
    end

    it 'returns customer' do
      token = JwtService.encode(id: customer.id)
      auth = "Bearer #{token}"
      request = { headers: { 'Authorization' => auth } }
      allow(subject).to receive(:request).and_return(OpenStruct.new(request))

      expect(subject.current_customer).to be_instance_of(Customer)
    end
  end
end
