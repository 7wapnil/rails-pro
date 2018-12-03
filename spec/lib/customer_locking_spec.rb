describe CustomerLocking do
  describe '#to_h' do
    let(:customer) do
      create(
        :customer,
        locked: true,
        lock_reason: :closed,
        locked_until: Time.zone.now + 2.weeks
      )
    end

    let(:subject) { described_class.new(customer) }

    it 'returns hash' do
      expected_result = {
        date:
          I18n.l(customer.locked_until, format: :date_picker),
        locked: true,
        reason:
          I18n.t("lock_reasons.#{customer.lock_reason}")
      }
      expect(subject.to_h).is_a? Hash
      expect(subject.to_h).to eq(expected_result)
    end
  end

  context 'with unlocked customer' do
    let(:customer) { create(:customer) }

    let(:subject) { described_class.new(customer) }

    it 'returns correct locked' do
      expect(subject.locked).to be_falsey
    end

    it 'returns correct reason' do
      expect(subject.reason).to be_nil
    end

    it 'returns correct date' do
      expect(subject.date).to be_nil
    end
  end

  context 'with infinite locked customer' do
    let(:customer) do
      create(
        :customer,
        locked: true,
        lock_reason: :closed
      )
    end

    let(:subject) { described_class.new(customer) }

    it 'returns correct locked' do
      expect(subject.locked).to be_truthy
    end

    it 'returns correct reason' do
      expect(subject.reason).to eq(
        I18n.t("lock_reasons.#{customer.lock_reason}")
      )
    end

    it 'returns correct date' do
      expect(subject.date).to eq(
        I18n.t('infinite')
      )
    end
  end

  context 'with locked for 2 weeks customer' do
    let(:customer) do
      create(
        :customer,
        locked: true,
        lock_reason: :closed,
        locked_until: Time.zone.now + 2.weeks
      )
    end

    let(:subject) { described_class.new(customer) }

    it 'returns correct locked' do
      expect(subject.locked).to be_truthy
    end

    it 'returns correct reason' do
      expect(subject.reason).to eq(
        I18n.t("lock_reasons.#{customer.lock_reason}")
      )
    end

    it 'returns correct date' do
      expect(subject.date).to eq(
        I18n.l(customer.locked_until, format: :date_picker)
      )
    end
  end
end
