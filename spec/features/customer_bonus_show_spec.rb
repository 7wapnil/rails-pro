require 'action_view'

describe CustomerBonus, '#show' do
  context 'displaying a bonus' do
    subject do
      create(:customer_bonus,
             rollover_balance: Faker::Number.decimal(2, 2),
             rollover_initial_value: Faker::Number.decimal(2, 2),
             balance_entry: balance_entry)
    end

    let(:entry) { create(:entry, :bonus_change) }
    let(:bonus_balance) { create(:balance, :bonus) }
    let(:balance_entry) do
      create(:balance_entry, entry: entry, balance: bonus_balance)
    end

    before do
      login_as create(:admin_user), scope: :user
      visit customer_bonus_path(subject)
    end

    it 'shows customer bonus rollover balance' do
      expect(page).to have_content(subject.rollover_balance)
    end

    it 'shows customer bonus initial rollover value' do
      expect(page).to have_content(subject.rollover_initial_value)
    end
  end
end
