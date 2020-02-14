# frozen_string_literal: true

module EveryMatrix
  class TablesQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType] do
      field :category, !EveryMatrix::CategoryType
    end

    description 'List of casino tables'

    argument :context, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      find_category!(args)

      EveryMatrix::PlayItemsResolver.call(
        model: EveryMatrix::Table,
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
      @category = Category.friendly.find(args['context'])
    end
  end
end
