# frozen_string_literal: true

describe RatioCalculator do
  subject { described_class.call(params) }

  let(:params) do
    {
      real_money_amount: real_money_amount,
      bonus_amount: bonus_amount
    }
  end

  let(:bonus_amount) { rand(1000.0).to_f }
  let(:real_money_amount) { rand(1000.0).to_f }

  it 'returns current ratio' do
    ratio = (real_money_amount / (real_money_amount + bonus_amount)).round(5)
    expect(subject).to eq(ratio)
  end

  context 'with zero bonus amount' do
    let(:bonus_amount) { 0.0 }

    it 'returns full ratio' do
      expect(subject).to eq(RatioCalculator::FULL_RATIO)
    end
  end

  context 'with bonus amount as nil' do
    let(:bonus_amount) { nil }

    it 'returns full ratio' do
      expect(subject).to eq(RatioCalculator::FULL_RATIO)
    end
  end

  context 'with zero real amount' do
    let(:real_money_amount) { 0.0 }

    it 'returns zero ratio' do
      expect(subject).to be_zero
    end
  end

  context 'with real amount as nil' do
    let(:real_money_amount) { nil }

    it 'returns zero ratio' do
      expect(subject).to be_zero
    end
  end
end
