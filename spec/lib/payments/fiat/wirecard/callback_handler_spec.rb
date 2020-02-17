# frozen_string_literal: true

describe Payments::Fiat::Wirecard::CallbackHandler do
  include_context 'wirecard_env'

  subject { described_class.call(request) }

  let(:entry_request) { create(:entry_request, origin: origin) }

  context 'when deposit' do
    let(:origin) { create(:deposit) }
    let(:request) do
      OpenStruct.new(
        params: {
          'request_id' => entry_request.id,
          'response-base64' => base64_body
        }
      )
    end
    let(:base64_body) { Base64.encode64(body.to_json) }
    let(:body) do
      {
        'payment' => {
          'transaction-type' => 'purchase'
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
    let(:origin) { create(:withdrawal) }
    let(:request) do
      OpenStruct.new(
        body: OpenStruct.new(
          string: body.to_xml
        ),
        params: ActionController::Parameters.new(
          request_id: entry_request.id
        )
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
