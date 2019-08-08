# frozen_string_literal: true

describe Payments::Fiat::Wirecard::CallbackHandler do
  include_context 'wirecard_env'

  subject { described_class.call(request) }

  context 'when deposit' do
    let(:request) do
      OpenStruct.new(
        params: {
          'response-base64' => base64_body
        }
      )
    end
    let(:base64_body) { Base64.encode64(body.to_json) }
    let(:body) do
      {
        'payment' => {
          'transaction-type' => 'authorization'
        }
      }
    end

    before do
      allow(Payments::Fiat::Wirecard::Deposits::CallbackHandler)
        .to receive(:call)
    end

    it { is_expected.to be_nil }
  end

  context 'when payout' do
    let(:request) do
      OpenStruct.new(
        body: OpenStruct.new(
          string: body.to_xml
        ),
        params: {}
      )
    end
    let(:body) do
      Nokogiri::XML::Builder.new do |xml|
        xml.payment do
          xml.send(:'transaction-type', 'credit')
        end
      end
    end

    before do
      allow(Payments::Fiat::Wirecard::Payouts::CallbackHandler)
        .to receive(:call)
    end

    it { is_expected.to be_nil }
  end
end
