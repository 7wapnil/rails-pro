class EntryRequestForm
  include Capybara::DSL

  def fill_in_with(params = {})
    fill_in 'Amount', with: params.fetch(:amount, 10)
    fill_in 'Comment', with: params.fetch(:comment, 'Comment text')
    select params.fetch(:mode, 'Cashier').capitalize, from: 'Mode'
    select params.fetch(:type, 'Deposit').capitalize, from: 'Type'
    select params.fetch(:currency, 'Euro'), from: 'Currency'

    self
  end

  def submit(button_name = 'Confirm')
    click_on(button_name)
  end
end
