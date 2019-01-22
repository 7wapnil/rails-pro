describe Deposit::CallbackUrl do
  let(:frontend_url) { Faker::Internet.url }

  before do
    allow(ENV).to receive(:[])
      .with('FRONTEND_URL')
      .and_return(frontend_url)
  end

  describe '.url' do
    described_class::CALLBACK_OPTIONS.each do |endoint, data|
      context "when #{endoint} callback url requested" do
        it 'generates correct url' do
          url = frontend_url +
                '?' +
                { depositState: data[:kind],
                  depositStateMessage: data[:message] }.compact.to_query
          expect(described_class.new(state: endoint).url).to eq url
        end
      end
    end

    let(:message) { Faker::Lorem.sentence(5) }

    it 'uses custom message when available' do
      url = frontend_url +
            '?' +
            { depositState: 'fail',
              depositStateMessage: message }.compact.to_query
      expect(
        described_class.new(state: :failed_entry_request, message: message).url
      ).to eq url
    end
  end
end
