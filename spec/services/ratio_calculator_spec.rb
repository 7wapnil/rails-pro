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

  context 'when same real and bonus money are passed' do
    let(:bonus_amount) { 50 }
    let(:real_money_amount) { 50 }

    it 'returns current ratio' do
      expect(subject).to eq(0.5)
    end
  end

  context 'when half bonus money are passed' do
    let(:bonus_amount) { 25 }
    let(:real_money_amount) { 50 }

    it 'returns current ratio' do
      expect(subject).to eq(0.66667)
    end
  end

  context 'when half real money are passed' do
    let(:bonus_amount) { 50 }
    let(:real_money_amount) { 25 }

    it 'returns current ratio' do
      expect(subject).to eq(0.33333)
    end
  end

  context 'when 1/3 real money are passed' do
    let(:bonus_amount) { 75 }
    let(:real_money_amount) { 25 }

    it 'returns current ratio' do
      expect(subject).to eq(0.25)
    end
  end

  context 'when 1/3 bonus money are passed' do
    let(:bonus_amount) { 25 }
    let(:real_money_amount) { 75 }

    it 'returns current ratio' do
      expect(subject).to eq(0.75)
    end
  end

  context 'when bonus money are not passed' do
    let(:bonus_amount) {}
    let(:real_money_amount) { 50 }

    it 'returns current ratio' do
      expect(subject).to eq(1.0)
    end
  end

  context 'when real money are not passed' do
    let(:bonus_amount) { 50 }
    let(:real_money_amount) {}

    it 'returns current ratio' do
      expect(subject).to be_zero
    end
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
