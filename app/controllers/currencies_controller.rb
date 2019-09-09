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
    @currency =
      Currencies::Create.call(params: currency_params,
                              current_user: current_user)

    return redirect_to currencies_path if @currency.errors.empty?

    render 'new'
  end

  def update
    @currency =
      Currencies::Update.call(params: currency_params,
                              current_user: current_user)

    return redirect_to currencies_path if @currency.errors.empty?

    render 'edit'
  end

  private

  def currency_params
    params
      .require(:currency)
      .permit(:id,
              :code,
              :name,
              :kind,
              entry_currency_rules_attributes: %i[id
                                                  kind
                                                  min_amount
                                                  max_amount])
  end
end
