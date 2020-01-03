require 'action_view'

describe EveryMatrix::Transaction, '#show' do
  include ActionView::Helpers::NumberHelper
  subject { create(:every_matrix_transaction, :random) }

  let!(:currency) { create(:currency, :primary) }

  context 'page content' do
    before do
      login_as create(:admin_user), scope: :user
      visit every_matrix_transaction_path(subject)
    end

    it 'shows transaction details' do
      %i[
        id transaction_id round_id
        device currency amount round_status
      ].each do |attribute|
        expect(page).to have_content(subject.public_send(attribute))
      end

      expect(page).to have_content(subject.play_item.id)
      expect(page).to have_content(subject.type.demodulize)
      expect(page).to have_content(subject.vendor.name)
      expect(page).to have_content(subject.content_provider.name)
    end
  end
end
