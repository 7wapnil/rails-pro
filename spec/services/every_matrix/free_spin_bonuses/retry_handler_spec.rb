# frozen_string_literal: true

describe EveryMatrix::FreeSpinBonuses::RetryHandler do
  subject do
    described_class.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
  end

  let(:free_spin_bonus_wallet) { create(:free_spin_bonus_wallet) }

  before do
    allow(EveryMatrix::FreeSpinBonuses::AwardBonusHandler)
      .to receive(:call)
      .and_return(true)
    allow(EveryMatrix::FreeSpinBonuses::ForfeitBonusHandler)
      .to receive(:call)
      .and_return(true)
  end

  context 'with error on create user' do
    before do
      free_spin_bonus_wallet.update_column(:status, 'user_created_with_error')
    end

    it 'calls award bonus' do
      subject

      expect(EveryMatrix::FreeSpinBonuses::AwardBonusHandler)
        .to have_received(:call)
    end
  end

  context 'with error on award bonus' do
    before do
      free_spin_bonus_wallet.update_column(:status, 'awarded_with_error')
    end

    it 'calls award bonus' do
      subject

      expect(EveryMatrix::FreeSpinBonuses::AwardBonusHandler)
        .to have_received(:call)
    end
  end

  context 'with error on forfeit bonus' do
    before do
      free_spin_bonus_wallet.update_column(:status, 'forfeited_with_error')
    end

    it 'calls forfeit bonus' do
      subject

      expect(EveryMatrix::FreeSpinBonuses::ForfeitBonusHandler)
        .to have_received(:call)
    end
  end
end
