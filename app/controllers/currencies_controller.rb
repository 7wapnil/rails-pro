class CurrenciesController < ApplicationController
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
    @currency = Currency.find(params[:id])
    EntryKinds::KINDS.keys.each do |kind|
      next if @currency.entry_currency_rules.exists?(kind: kind)

      @currency.entry_currency_rules.build(kind: kind,
                                           min_amount: 0,
                                           max_amount: 0)
    end
  end

  def create
    @currency = Currency.new(currency_params)

    if @currency.save
      current_user.log_event :currency_created, @currency
      redirect_to currencies_path
    else
      render 'new'
    end
  end

  def update
    @currency = Currency.find(params[:id])

    if @currency.update(currency_params)
      current_user.log_event :currency_updated, @currency
      redirect_to currencies_path
    else
      render 'edit'
    end
  end

  private

  def currency_params
    params
      .require(:currency)
      .permit(:code,
              :name,
              :kind,
              entry_currency_rules_attributes: %i[id
                                                  kind
                                                  min_amount
                                                  max_amount])
  end
end
