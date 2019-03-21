# frozen_string_literal: true

describe MarketTemplate do
  subject { build(:market_template) }

  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:name) }

  describe '#variants?' do
    context 'positive' do
      subject { build(:market_template, payload: { variants: true }) }

      it { expect(subject.variants?).to eq(true) }
    end

    it 'negative' do
      expect(subject.variants?).to eq(false)
    end
  end
end
