describe Radar::Client do
  context 'client api' do
    let(:options) do
      { headers: { "x-access-token": ENV['RADAR_API_TOKEN'],
                   "content-type": 'application/xml' } }
    end

    it 'should request whoami endpoint' do
      allow(subject.class).to receive(:get).with('/users/whoami.xml', options)
      subject.who_am_i
    end
  end
end
