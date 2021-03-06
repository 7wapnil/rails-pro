# frozen_string_literal: true

describe Wallets::CreateForm do
  context '#submit!' do
    subject { described_class.new(subject: wallet).submit! }

    let(:wallet) { build(:wallet) }
    let!(:crypto_currency) { create :currency, :crypto }

    context 'when there is a duplicate, but that is crypto-wallet' do
      let!(:second_wallet) do
        create(:wallet, customer: wallet.customer, currency: crypto_currency)
      end

      it 'creates the wallet' do
        subject
        expect(wallet).to be_persisted
      end
    end

    context 'when created wallet is crypto-wallet and has another crypto' do
      let(:wallet) { build(:wallet, :crypto) }
      let!(:second_wallet) do
        other_crypto_currency = create(:currency, :crypto, code: 'CCC')
        create(:wallet,
               customer: wallet.customer,
               currency: other_crypto_currency)
      end

      it 'creates the wallet' do
        subject
        expect(wallet).to be_persisted
      end
    end

    context 'when there is the same duplicate' do
      let!(:second_wallet) do
        create(:wallet, customer: wallet.customer, currency: wallet.currency)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          ActiveModel::ValidationError,
          'Validation failed: ' \
          "#{I18n.t('internal.errors.messages.wallets.not_unique')}"
        )
      end

      it 'does not create the wallet' do
        subject
      rescue ActiveModel::ValidationError
        expect(wallet).not_to be_persisted
      end
    end

    context 'when crypto wallet has the same duplicate' do
      let(:wallet) { build(:wallet, :crypto) }
      let!(:second_wallet) do
        create(:wallet, customer: wallet.customer, currency: wallet.currency)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          ActiveModel::ValidationError,
          'Validation failed: ' \
          "#{I18n.t('internal.errors.messages.wallets.not_unique')}"
        )
      end

      it 'does not create the wallet' do
        subject
      rescue ActiveModel::ValidationError
        expect(wallet).not_to be_persisted
      end
    end

    context 'when there is a duplicate, but that is FIAT wallet' do
      let!(:second_wallet) do
        other_fiat_currency = create(:currency, code: 'XXX')
        create(:wallet,
               customer: wallet.customer,
               currency: other_fiat_currency)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          ActiveModel::ValidationError,
          'Validation failed: ' \
          "#{I18n.t('internal.errors.messages.wallets.fiat_not_unique')}"
        )
      end

      it 'does not create the wallet' do
        subject
      rescue ActiveModel::ValidationError
        expect(wallet).not_to be_persisted
      end
    end

    context 'when amount is non-numerical' do
      let(:wallet) { build(:wallet, amount: nil) }

      it 'does not create the wallet' do
        subject
      rescue ActiveModel::ValidationError
        expect(wallet).not_to be_persisted
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end
end
