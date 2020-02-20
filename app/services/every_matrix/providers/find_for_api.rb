# frozen_string_literal: true

module EveryMatrix
  module Providers
    class FindForApi < ApplicationService
      def initialize(slug:)
        @slug = slug
      end

      def call
        find_vendor || find_content_provider
      end

      private

      attr_reader :slug

      def find_vendor
        EveryMatrix::Vendor.visible.find_by!(slug: slug)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def find_content_provider
        EveryMatrix::ContentProvider.visible.as_vendor.find_by!(slug: slug)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
