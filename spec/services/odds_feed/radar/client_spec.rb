# frozen_string_literal: true

describe OddsFeed::Radar::Client do
  let(:object) { described_class.instance }

  let(:headers) { { "x-access-token": 'test-api-token' } }
  let!(:api_domain) { 'https://test-api-domain' }

  before do
    described_class.base_uri(api_domain)
    described_class.headers(headers)
  end

  context 'routes' do
    it 'requests whoami endpoint' do
      body = file_fixture('api/who_am_i_response.xml').read

      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: body)

      object.who_am_i
    end
  end

  context 'unexpected responses' do
    let(:forbidden_response) do
      file_fixture('api/forbidden_response.xml').read
    end
    let(:invalid_xml) { '<doctype><html><body>Hello World</body></html>' }

    it 'raise error on 403' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 403, body: forbidden_response)

      expect { object.who_am_i }.to raise_error(HTTParty::ResponseError)
    end

    it 'raises error on invalid xml' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: invalid_xml)

      expect { object.who_am_i }
        .to raise_error(HTTParty::ResponseError, 'Malformed response body')
    end

    it 'raises error on plain text' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: 'Plain text')

      expect { object.who_am_i }
        .to raise_error(HTTParty::ResponseError, 'Malformed response body')
    end
  end

  describe '#event' do
    let(:event_id) { 'sr:match:10001' }
    let(:route) do
      "#{api_domain}/sports/en/sport_events/#{event_id}/fixture.xml"
    end

    it 'returns an adapter' do
      stub_request(:any, route).with(headers: headers).to_return(body: '')

      expect(object.event(event_id)).to be_a(OddsFeed::Radar::EventAdapter)
    end

    context 'handle unexpected event types' do
      let(:event_id) { 'sr:season:10001' }

      it 'and returns an adapter' do
        expect(object.event(event_id)).to be_a(OddsFeed::Radar::EventAdapter)
      end

      it "and doesn't try to achieve Radar API" do
        expect(OddsFeed::Radar::ResponseReader).not_to receive(:call)
        object.event(event_id)
      end
    end
  end

  describe '#product_recovery_initiate_request' do
    let(:recover_after) { Faker::Time.backward(2) }
    let(:recover_after_milliseconds_timestamp) do
      recover_after.to_datetime.strftime('%Q')
    end
    let(:product_code) { Faker::Lorem.word.to_sym }

    before do
      allow(object).to receive(:log_job_message)
      allow(object).to receive(:post)
    end

    context 'with requires arguments only' do
      let(:expected_path) do
        "/#{product_code}/recovery/initiate_request?after="\
        "#{recover_after_milliseconds_timestamp}"
      end

      before do
        object.product_recovery_initiate_request(
          product_code: product_code, after: recover_after
        )
      end

      it 'logs job message' do
        log_message = 'Calling subscription recovery'
        expect(object).to have_received(:log_job_message)
          .with(:info, message: log_message, route: expected_path).once
      end
      it 'post to correct path' do
        expect(object).to have_received(:post)
          .with(expected_path).once
      end
    end

    context 'with all options provided' do
      let(:request_id) { Faker::Number.number(4) }
      let(:node_id) { Faker::Number.number(4) }

      let(:expected_path) do
        query_string = "after=#{recover_after_milliseconds_timestamp}&" \
                       "node_id=#{node_id}&" \
                       "request_id=#{request_id}"

        "/#{product_code}/recovery/initiate_request?#{query_string}"
      end

      before do
        object.product_recovery_initiate_request(
          product_code: product_code, after: recover_after,
          request_id: request_id, node_id: node_id
        )
      end

      it 'logs job message' do
        expect(object).to have_received(:log_job_message)
          .with(
            :info,
            message: 'Calling subscription recovery',
            route: expected_path
          ).once
      end
      it 'post to correct path' do
        expect(object).to have_received(:post)
          .with(expected_path).once
      end
    end
  end

  describe '#all_market_variants' do
    let(:route) { '/descriptions/en/variants.xml' }
    let(:cache_arguments) { Faker::Types.complex_rb_hash }

    before do
      allow(OddsFeed::Radar::ResponseReader).to receive(:call)
      object.all_market_variants(cache: cache_arguments)
    end

    it 'reaches Radar API response' do
      expect(OddsFeed::Radar::ResponseReader)
        .to have_received(:call)
        .with(path: route, method: :get, cache: cache_arguments)
    end
  end
end
