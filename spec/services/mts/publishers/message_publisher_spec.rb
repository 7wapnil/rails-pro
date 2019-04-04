# frozen_string_literal: true

describe Mts::Publishers::MessagePublisher do
  subject { described_class.new(bet: bet) }

  let(:bet) { create(:bet) }

  describe '#publish!' do
    it 'raise unimplemented error' do
      expect { subject.publish! }.to raise_error(NotImplementedError)
    end
  end
end
