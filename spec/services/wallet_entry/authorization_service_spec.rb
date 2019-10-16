# frozen_string_literal: true

describe WalletEntry::AuthorizationService do
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: -500, max_amount: 500) }

  before do
    allow(EntryCurrencyRule).to receive(:find_by).and_return(rule)
    allow(Currency).to receive(:find_by!).and_return(currency)
  end

  context 'first entry' do
    let(:kind) { EntryKinds::DEPOSIT }
    let(:request) { create(:entry_request, :with_real_money, kind: kind) }
    let(:customer) { request.customer }
    let(:service) { described_class.new(request) }

    let(:entry) do
      Entry.joins(:wallet).where('wallets.customer_id': customer.id).first
    end

    context 'success' do
      it 'creates a wallet' do
        expect(Wallet.where(customer: customer).count).to eq 0
        described_class.call(request)
        expect(Wallet.where(customer: customer).count).to eq 1
        expect(Wallet.find_by(customer: customer).real_money_balance)
          .to eq request.amount
      end

      it 'creates a wallet entry' do
        time = Time.local(2008, 9, 1, 12, 0, 0)
        Timecop.freeze(time) do
          expect(Entry.count).to eq 0

          described_class.call(request)

          expect(entry).to be_present
          expect(entry.amount).to eq request.amount
          expect(entry.origin).to eq request.origin
          expect(entry.authorized_at).to eq time
          expect(entry.real_money_amount).to eq request.amount
          expect(entry.balance_amount_after)
            .to eq Wallet.find_by(customer: customer).real_money_balance
        end
      end

      it 'adds entry amount into wallet' do
        described_class.call(request)
        wallet = Wallet.find_by(customer_id: customer.id)
        expect(wallet.amount).to eq request.amount
      end

      it 'updates entry request' do
        expect_any_instance_of(described_class)
          .not_to receive(:handle_failure)

        described_class.call(request)

        expect(request.succeeded?).to be true
        expect(request.result).not_to be_present
      end

      it 'calls Audit::Service' do
        service.instance_variable_set :@entry, create(:entry, amount: 10)

        expect(Audit::Service)
          .to receive(:call)
          .with hash_including(event: :entry_request_created)

        service.send(:log_success)
      end

      it 'returns the created entry' do
        described_class.call(request)

        current_balance_amount = entry.wallet.real_money_balance +
                                 entry.wallet.bonus_balance

        expect(entry).to be_an Entry
        expect(entry.entry_request).to eq request
        expect(entry.balance_amount_after).to eq current_balance_amount
      end

      context 'entry confirmation' do
        let!(:wallet) do
          create(:wallet, :fiat, amount: 500,
                                 real_money_balance: 500,
                                 customer: request.customer,
                                 currency: request.currency)
        end

        include_context 'frozen_time'

        before { described_class.call(request) }

        it 'is performed' do
          expect(entry.confirmed_at).to eq(Time.zone.now)
        end

        context 'for entry with delayed confirmation' do
          let(:kind) { EntryKinds::DELAYED_CONFIRMATION_KINDS.sample }

          it 'is not performed' do
            expect(entry.confirmed_at).to be_nil
          end
        end
      end

      context 'summary' do
        include_context 'frozen_time'

        before do
          allow(::Customers::Summaries::UpdateBalance).to receive(:call)

          described_class.call(request)
        end

        it 'is re-calculated' do
          expect(::Customers::Summaries::UpdateBalance)
            .to have_received(:call)
            .with(day: Date.current, entry: entry)
        end

        context 'for bet entry' do
          let(:kind) { EntryKinds::BET }

          it 'is not re-calculated' do
            expect(::Customers::Summaries::UpdateBalance)
              .not_to have_received(:call)
          end
        end
      end
    end

    context 'failure' do
      before { request.amount = 600 }

      it 'updates entry request' do
        expect_any_instance_of(described_class)
          .not_to receive(:log_success)

        described_class.call(request)

        expect(request.failed?).to be true
        expect(request.result['exception_class'])
          .to eq 'ActiveRecord::RecordInvalid'
      end

      it 'calls Audit::Service' do
        expect(Audit::Service)
          .to receive(:call)
          .with hash_including(event: :entry_creation_failed)

        service.send(:handle_failure, StandardError.new)
      end

      it 'returns nil' do
        expect(described_class.call(request)).to be_nil
      end
    end
  end

  context 'existing wallet' do
    let!(:wallet) { create(:wallet, amount: 50, real_money_balance: 50) }

    let(:request) do
      create(:entry_request,
             customer: wallet.customer,
             currency: wallet.currency)
    end

    context 'increment' do
      before do
        request.kind = EntryKinds::DEPOSIT
        request.amount = 10
        request.real_money_amount = request.amount
      end

      it 'increments wallet amount' do
        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 60
      end

      it 'increments balance amount' do
        described_class.call(request)
        wallet.reload

        expect(wallet.real_money_balance).to eq 60
      end
    end

    context 'decrement' do
      let(:rule) do
        create(:entry_currency_rule, min_amount: -500, max_amount: 0)
      end

      before do
        allow(EntryCurrencyRule).to receive(:find_by!) { rule }
        request.kind = EntryKinds::WITHDRAW
      end

      it 'decrements wallet amount' do
        request.amount = -10
        request.real_money_amount = request.amount

        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 40
      end

      it 'decrements balance amount' do
        request.amount = -10
        request.real_money_amount = request.amount

        described_class.call(request)
        wallet.reload

        expect(wallet.real_money_balance).to eq 40
      end

      it 'fails to update wallet amount to negative' do
        error_message = I18n.t('errors.messages.amount_not_negative',
                               subject: wallet.to_s,
                               current_amount: wallet.amount,
                               new_amount: -10)

        request.amount = -60
        request.real_money_amount = request.amount

        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 50
        expect(request.failed?).to be true
        expect(request.result_message).to include error_message
      end

      it 'fails to update balance amount to negative' do
        wallet.update_attributes!(real_money_balance: 30)

        error_message = I18n.t('errors.messages.amount_not_negative',
                               subject: wallet.to_s,
                               current_amount: wallet.real_money_balance,
                               new_amount: -10)

        request.amount = -40
        request.real_money_amount = request.amount

        described_class.call(request)
        wallet.reload

        expect(wallet.real_money_balance).to eq 30
        expect(request.failed?).to be true
        expect(request.result_message).to include error_message
      end
    end
  end
end
