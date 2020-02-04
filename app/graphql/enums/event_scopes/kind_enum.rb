# frozen_string_literal: true

module EventScopes
  class KindEnum < Base::Enum
    graphql_name 'EventScopesKindEnum'

    description 'Event scope kind'

    value EventScope::TOURNAMENT, 'Tournament'
    value EventScope::CATEGORY, 'Category'
    value EventScope::SEASON, 'Season'
  end
end
