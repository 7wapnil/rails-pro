describe ApiController, type: :controller do
  context '#current_customer' do
    let(:subject_request) { described_class.new }
    let(:user) { create(:user) }
    let(:customer) { create(:customer) }

    it 'returns user when customer is impersonated' do
      token = JwtService.encode(impersonated_by: user.id, id: customer.id)
      auth = "Bearer #{token}"
      request = { headers: { 'Authorization' => auth } }
      allow(
        subject_request
      ).to receive(:request).and_return(OpenStruct.new(request))

      expect(subject_request.impersonated_by).to eq(user)
    end

    it 'returns nil when customer is not impersonated' do
      token = JwtService.encode(id: customer.id)
      auth = "Bearer #{token}"
      request = { headers: { 'Authorization' => auth } }
      allow(
        subject_request
      ).to receive(:request).and_return(OpenStruct.new(request))

      expect(subject_request.impersonated_by).to be_nil
    end
  end
end
