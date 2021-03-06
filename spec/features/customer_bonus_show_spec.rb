require 'action_view'

describe CustomerBonus, '#show' do
  context 'displaying a bonus' do
    subject do
      create(:customer_bonus,
             rollover_balance: Faker::Number.decimal(2, 2),
             rollover_initial_value: Faker::Number.decimal(2, 2),
             activation_entry: entry)
    end

    let(:entry) do
      create(:entry, :bonus_change, bonus_amount: Faker::Number.decimal(2, 2))
    end

    before do
      login_as create(:admin_user), scope: :user
      visit customer_bonus_path(subject)
    end

    it 'shows customer bonus rollover balance' do
      expect(page).to have_content(
        "#{subject.rollover_balance} #{subject.wallet.currency.code}"
      )
    end

    it 'shows customer bonus initial rollover value' do
      expect(page).to have_content(
        "#{subject.rollover_initial_value} #{subject.wallet.currency.code}"
      )
    end
  end
end
