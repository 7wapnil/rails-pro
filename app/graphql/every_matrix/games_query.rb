# frozen_string_literal: true

module EveryMatrix
  class GamesQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType] do
      field :category, !EveryMatrix::CategoryType
    end

    description 'List of casino games'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      find_category!(args)

      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Game,
        category: @category,
        device: platform_type(@request),
        country: @request.location.country_code.upcase
      )
    end

    private

    def extend_pagination_result(*)
      { category: @category }
    end

    def find_category!(args)
      @category = Category.find_by!(context: args['context'])
    end
  end
end
