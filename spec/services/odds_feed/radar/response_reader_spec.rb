describe OddsFeed::Radar::ResponseReader do
  subject { described_class.call(params) }

  let(:response) { OpenStruct.new(parsed_response: data) }
  let(:data)     { Faker::Types.complex_rb_hash }

  let(:path)      { '/users/whoami.xml' }
  let(:cache_key) { "#{OddsFeed::Radar::ResponseReader::CLIENT_KEY}:#{path}" }
  let(:cache)     {}
  let(:options)   { { access_token: Faker::Number.number(4) } }

  let(:params) do
    {
      path:    path,
      method:  :get,
      cache:   cache,
      options: options
    }
  end

  before do
    allow(OddsFeed::Radar::Client)
      .to receive(:get)
      .with(path, options)
      .and_return(response)
  end

  context 'radar api call' do
    context 'and cache data without settings' do
      let(:cache) { true }

      before do
        expect(Rails.cache).to receive(:write).with(cache_key, data, {})
      end

      it { expect(subject).to eq(data) }
    end

    context 'and cache data with with settings' do
      let(:cache) do
        {
          cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
        }
      end

      before do
        expect(Rails.cache).to receive(:write).with(cache_key, data, cache)
      end

      it { expect(subject).to eq(data) }
    end

    context 'without caching' do
      before { expect(Rails.cache).not_to receive(:write) }

      it { expect(subject).to eq(data) }
    end
  end

  context 'cached value' do
    let(:cache) { true }

    before do
      allow(Rails.cache)
        .to receive(:read)
        .with(cache_key)
        .and_return(data)

      expect(OddsFeed::Radar::Client).not_to receive(:get)
    end

    it { expect(subject).to eq(data) }
  end
end
