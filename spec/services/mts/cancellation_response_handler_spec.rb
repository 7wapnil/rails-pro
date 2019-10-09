# frozen_string_literal: true

describe Mts::CancellationResponseHandler do
  include_context 'asynchronous to synchronous'
  let(:subject_call) { described_class.call(message: message) }
  let!(:primary_currency) { create(:currency, :primary) }
  let!(:bet) do
    create(:bet, :with_placement_entry, :sent_to_external_validation,
           validation_ticket_id: ticket_id)
  end
  let!(:ticket_id) { "MTS_Test_#{Faker::Number.number(13)}" }
  let(:message) do
    <<-EXAMPLE_JSON
      {"result": {
        "ticketId": "#{ticket_id}",
          "reason": {
               "code": #{status_code},
            "message": ""
          }
        },
        "signature": "NJ4dU508yDnDhPzDOiSlhxwxfsTWDOtyZ6TOaHZG2W4=",
        "version": "2.3"
      }
    EXAMPLE_JSON
  end

  describe '.call' do
    let(:refund_entry_request) { bet.refund_request }

    context 'successful cancellation' do
      let(:status_code) { Mts::Codes::SUCCESSFUL_CODE }

      it 'changes bet status' do
        subject_call
        bet.reload

        expect(bet.status).to eql(Bet::CANCELLED)
      end

      it 'creates refund entry request' do
        subject_call

        expect(refund_entry_request.kind).to eql(EntryRequest::REFUND)
      end

      it 'starts refund worker' do
        expect(EntryRequests::BetCancellationWorker).to receive(:perform_async)

        subject_call
      end
    end

    context 'unsuccessful cancellation' do
      let(:status_code) do
        Mts::Codes::CANCELLATION_ERROR_CODES.keys.sample
      end

      it 'changes bet status' do
        subject_call
        bet.reload

        expect(bet.status).to eql(Bet::PENDING_MTS_CANCELLATION)
      end

      it 'creates refund entry request' do
        subject_call

        expect(refund_entry_request.kind).to eql(EntryRequest::REFUND)
      end

      it 'starts refund worker' do
        expect(EntryRequests::BetCancellationWorker).to receive(:perform_async)

        subject_call
      end
    end

    context 'with nonexistent bet' do
      before do
        allow(Rails.logger)
          .to receive(:error)
          .with(message: error_message,
                id: ticket_id,
                error_object: kind_of(ActiveRecord::RecordNotFound))
      end

      let(:error_message) { I18n.t('errors.messages.nonexistent_bet') }
      let(:status_code) { Mts::Codes::SUCCESSFUL_CODE }
      let!(:bet) do
        create(:bet,
               :sent_to_external_validation,
               validation_ticket_id: "MTS_Test_#{Faker::Number.number(13)}")
      end

      it 'raises the error' do
        expect { subject_call }.to raise_error(StandardError)
      end

      it 'logs the error' do
        subject_call
        raise
      rescue StandardError
        expect(Rails.logger)
          .to have_received(:error)
          .with(message: error_message,
                id: ticket_id,
                error_object: kind_of(StandardError))
      end
    end
  end
end
