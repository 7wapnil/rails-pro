describe OddsFeed::Radar::Transpiler do
  let(:event_payload) do
    {
      'competitors' => {
        'competitor' => [
          { 'id' => '1000', 'name' => 'Player 1' },
          { 'id' => '1001', 'name' => 'Player 2' }
        ]
      }
    }
  end
  let(:event) { create(:event, payload: event_payload) }
  let(:market_id) { '1' }
  let(:specifiers) { 'set=1|game=2|point=3|variant=sr:exact_goals:9+' }
  subject do
    OddsFeed::Radar::Transpiler.new(event, market_id, specifiers)
  end

  it 'transpiles specifiers' do
    result = subject.transpile('Set is {set}, game is {game}, point is {point}')
    expect(result).to eq('Set is 1, game is 2, point is 3')
  end

  it 'transpiles event variables' do
    result = subject.transpile('{$competitor1} VS {$competitor2}')
    expect(result).to eq('Player 1 VS Player 2')
  end

  it 'returns transpiled market name' do
    create(:market_template,
           external_id: market_id,
           name: 'Set is {set}, game is {game}, point is {point}')

    expect(subject.market_name).to eq('Set is 1, game is 2, point is 3')
  end

  describe '#odd_name' do
    it 'transpiles odd values from market template' do
      create(:market_template,
             external_id: market_id,
             name: 'Market name',
             payload: {
               outcomes: {
                 outcome: [
                   { 'id': '321', 'name': '{$competitor1} win game nr.{game}' }
                 ]
               }
             })

      expect(subject.odd_name('321'))
        .to eq('Player 1 win game nr.2')
    end

    it 'takes odd values from market variants API' do
      allow(subject).to receive(:variant_odds) do
        {
          'outcomes' => {
            'outcome' => [
              { 'id' => 'sr:exact_goals:9+_2:104', 'name' => '0-1' },
              { 'id' => 'sr:exact_goals:9+_2:105', 'name' => '2' }
            ]
          }
        }
      end

      create(:market_template,
             external_id: market_id,
             name: 'Market name',
             payload: { outcomes: nil })

      expect(subject.odd_name('sr:exact_goals:9+_2:104')).to eq('0-1')
    end

    it 'raises an error' do
      allow(subject).to receive(:variant_odds).and_return({})
      create(:market_template,
             external_id: market_id,
             name: 'Market name',
             payload: {
               outcomes: nil
             })

      expect { subject.odd_name('321') }.to raise_error(
        StandardError,
        'Odd template ID 321 not found'
      )
    end
  end
end
