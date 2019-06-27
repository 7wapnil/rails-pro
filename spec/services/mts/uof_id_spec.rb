describe Mts::UofId do
  describe '#initialize' do
    context 'with missing producer' do
      let(:odd) { create(:odd) }

      before do
        odd.market.event.update(producer: nil)
      end

      it 'raises an error' do
        expect do
          described_class.new(odd)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#uof_id' do
    [
      {
        title: 'odd with specifiers',
        market_id: '186',
        market_specifier: 'setnr=1|gamenr=2',
        outcome_id: '4',
        external_id: 'sr:match:15868492:186/setnr=1|gamenr=2:4',
        uof_id: 'uof:1/sr:sport:110/186/4?setnr=1&gamenr=2'
      },
      {
        title: 'odd without specifiers',
        market_id: '186',
        market_specifier: '',
        outcome_id: '4',
        external_id: 'sr:match:15868492:186:4',
        uof_id: 'uof:1/sr:sport:110/186/4'
      },
      {
        title: 'in respect with producer',
        market_id: '186',
        market_specifier: 'setnr=1|gamenr=2',
        outcome_id: '4',
        external_id: 'sr:match:15868492:186/setnr=1|gamenr=2:4',
        producer_id: '3',
        uof_id: 'uof:3/sr:sport:110/186/4?setnr=1&gamenr=2'
      },
      {
        title: 'odd with variant specifiers',
        market_id: '15',
        market_specifier: 'variant=sr:winning_margin:3+',
        outcome_id: 'sr:winning_margin:3+:113',
        external_id: 'sr:match:17790410:15/' \
          'variant=sr:winning_margin:3+:sr:winning_margin:3+:113',
        producer_id: '3',
        uof_id: 'uof:3/sr:sport:110/15/' \
          'sr:winning_margin:3+:113?variant=sr:winning_margin:3+'
      }
    ].each do |example|
      context example[:title] do
        subject { described_class.new(odd) }

        let(:producer) do
          create(:producer, id: example[:producer_id] || '1')
        end
        let(:title) { create(:title, external_id: 'sr:sport:110') }
        let(:event) do
          create(:event,
                 title: title,
                 producer: producer)
        end
        let(:market) do
          create(:market, event: event,
                          market_id: example[:market_id],
                          market_specifier: example[:market_specifier])
        end
        let(:odd) do
          create(:odd,
                 market: market,
                 external_id: example[:external_id],
                 outcome_id: example[:outcome_id])
        end

        it "generates correct uof id for #{example[:title]}" do
          expect(subject.uof_id).to eq example[:uof_id]
        end
      end
    end
  end
end
