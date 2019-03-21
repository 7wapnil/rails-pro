# frozen_string_literal: true

describe WebSocket::Client do
  subject { described_class.instance }

  describe 'event updates' do
    let(:event) do
      event = create(:event)
      event.event_scopes << create(:event_scope, kind: EventScope::TOURNAMENT)
      event.event_scopes << create(:event_scope, kind: EventScope::CATEGORY)
      event
    end

    before do
      subject.trigger_event_update(event)
    end

    it 'triggers all events subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::EVENTS_UPDATED, event)
    end

    it 'triggers single event subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::EVENT_UPDATED, event, id: event.id)
    end

    it 'triggers kind events subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::KIND_EVENT_UPDATED,
          event,
          kind: event.title.kind
        )
    end

    it 'triggers sport events subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::SPORT_EVENT_UPDATED,
          event,
          title: event.title_id
        )
    end

    it 'triggers category events subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::CATEGORY_EVENT_UPDATED,
          event,
          category: event.category.id
        )
    end

    it 'triggers tournament events subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::TOURNAMENT_EVENT_UPDATED,
          event,
          tournament: event.tournament.id
        )
    end
  end

  describe 'market updates' do
    let(:market) { create(:market) }

    before do
      subject.trigger_market_update(market)
    end

    it 'triggers single market subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::MARKET_UPDATED, market, id: market.id)
    end

    it 'triggers event markets subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::EVENT_MARKET_UPDATED,
          market,
          eventId: market.event_id
        )
    end

    it 'triggers category markets subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(
          SubscriptionFields::CATEGORY_MARKET_UPDATED,
          market,
          eventId: market.event_id, category: market.category
        )
    end
  end

  describe 'providers updates' do
    let(:provider) { create(:producer) }

    it 'triggers app state subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::PROVIDER_UPDATED, provider)
    end
  end

  describe 'wallets updates' do
    let(:wallet) { create(:wallet) }

    it 'triggers wallet update subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::WALLET_UPDATED,
              wallet,
              {},
              wallet.customer_id)
    end
  end

  describe 'bets updates' do
    let(:bet) { create(:bet) }

    before do
      subject.trigger_bet_update(bet)
    end

    it 'triggers wallet update subscription' do
      expect(subject)
        .to have_received(:trigger)
        .with(SubscriptionFields::BET_UPDATED,
              bet,
              { id: bet.id },
              bet.customer_id)
    end
  end
end
