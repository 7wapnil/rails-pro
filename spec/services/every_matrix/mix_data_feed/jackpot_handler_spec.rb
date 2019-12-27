# frozen_string_literal: true

describe EveryMatrix::MixDataFeed::JackpotHandler do
  subject { described_class.call(payload) }

  let(:payload) do
    JSON.parse(file_fixture('casino/jackpot_sample_fixture.json').read)
  end

  describe 'new jackpot' do
    it 'creates new jackpot' do
      expect { subject }.to change(EveryMatrix::Jackpot, :count).by(1)
    end
  end

  describe 'existing jackpot' do
    let!(:jackpot) do
      create(:jackpot, external_id: data['id'], base_currency_amount: 0)
    end
    let(:data) { payload['data'] }

    it 'updates jackpot' do
      subject

      expect(jackpot.reload.base_currency_amount)
        .to eq(payload['data']['amounts']['EUR'])
    end

    it 'does not create new jackpot record' do
      expect { subject }.not_to change(EveryMatrix::Jackpot, :count)
    end
  end
end
