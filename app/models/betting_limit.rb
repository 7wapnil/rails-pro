class BettingLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :title, optional: true

  validates :customer, presence: true
  validates :customer, uniqueness: { scope: :title }

  def validate!(bet)
    @bet = bet
    @money_converter = MoneyConverter::Service.new
    validate_user_max_bet!
    validate_max_win!
    validate_max_loss!
    validate_user_stake_factor!
    validate_live_stake_factor!
  end

  private

  def validate_user_max_bet!
    value = @money_converter
            .convert(@bet.amount, @bet.currency.code)
    return if user_max_bet.nil? || user_max_bet > value

    @bet.errors.add(:amount, :user_max_bet)
  end

  def validate_max_win!
    value = @money_converter
            .convert(@bet.potential_win, @bet.currency.code)
    return if max_win.nil? || max_win > value

    @bet.errors.add(:amount, :max_win)
  end

  def validate_max_loss!
    value = @money_converter
            .convert(@bet.potential_loss, @bet.currency.code)
    return if max_loss.nil? || max_loss > value

    @bet.errors.add(:amount, :max_loss)
  end

  def validate_user_stake_factor!
    # TODO: Implementation needed
    true
  end

  def validate_live_stake_factor!
    # TODO: Implementation needed
    true
  end
end
