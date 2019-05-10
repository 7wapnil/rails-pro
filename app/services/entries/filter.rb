# frozen_string_literal: true

module Entries
  class Filter
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20
    DAY_OFFSET = 1.day

    attr_reader :source

    def initialize(source:, query_params: {}, **options)
      @source = source
      @query_params = query_params
      @page = options[:page].presence || DEFAULT_PAGE
      @per_page = options[:per_page].presence || DEFAULT_PER_PAGE

      set_created_at_filter!
    end

    def search
      @search ||= @source.ransack(@query_params, search_key: :entries)
    end

    def entries
      search.sorts = ['created_at desc'] if search.sorts.empty?
      search.result.page(@page).per(@per_page)
    end

    private

    def set_created_at_filter!
      return if created_at_filter.blank?

      @query_params[:created_at_lteq] = I18n.l(
        Date.parse(created_at_filter) + DAY_OFFSET
      )
    end

    def created_at_filter
      @query_params[:created_at_lteq]
    end
  end
end
