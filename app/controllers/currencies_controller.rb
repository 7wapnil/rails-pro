# frozen_string_literal: true

class CurrenciesController < ApplicationController
  find :currency, only: :edit

  decorates_assigned :currency

  def index
    @search = Currency.ransack(query_params)
    @currencies = @search.result.page(params[:page])
  end

  def new
    @currency = Currency.new
    EntryKinds::KINDS.keys.each do |kind|
      @currency.entry_currency_rules.build(kind: kind,
                                           min_amount: 0,
                                           max_amount: 0)
    end
  end

  def edit
    EntryKinds::KINDS.keys.each do |kind|
      next if @currency.entry_currency_rules.exists?(kind: kind)

      @currency.entry_currency_rules.build(kind: kind,
                                           min_amount: 0,
                                           max_amount: 0)
    end
  end

  def create
    @currency = Currencies::Create.call(params: currency_params,
                                        current_user: current_user)

    return render_form_on_failure(:new) if @currency.errors.any?

    redirect_to edit_currency_path(@currency),
                notice: t('currencies.create.success', code: @currency.code)
  end

  def update
    @currency = Currencies::Update.call(params: currency_params,
                                        current_user: current_user)

    return render_form_on_failure(:edit) if @currency.errors.any?

    redirect_to edit_currency_path(@currency),
                notice: t('currencies.update.success')
  end

  private

  def currency_params
    params
      .require(:currency)
      .permit(:id,
              :code,
              :name,
              :kind,
              entry_currency_rules_attributes: %i[
                id
                kind
                min_amount
                max_amount
              ])
  end

  def render_form_on_failure(action_key)
    flash[:alert] = @currency.errors.full_messages.first

    render action_key
  end
end
