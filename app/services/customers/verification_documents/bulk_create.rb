# frozen_string_literal: true

module Customers
  module VerificationDocuments
    class BulkCreate < ApplicationService
      def initialize(params:, customer:)
        @params = params
        @customer = customer
        @errors_list = {}
      end

      def call
        attach_documents!

        errors_list.empty? ? success_response : error_response
      end

      private

      attr_reader :params, :customer, :errors_list

      def attach_documents!
        params.each { |kind, file| attach_document(kind, file) }
      end

      def attach_document(kind, file)
        doc = Documents::CreateForm.new(document: file)

        doc.valid? ? save_document!(kind, file) : add_error(kind, doc)
      end

      def save_document!(kind, file)
        verification_document = customer
                                .verification_documents
                                .create(
                                  kind: kind,
                                  status: VerificationDocument::PENDING
                                )

        verification_document.document.attach(file)
      end

      def add_error(kind, document)
        @errors_list[kind] = document.errors.full_messages.join('; ')
      end

      def success_response
        { success: true }
      end

      def error_response
        {
          success: false,
          errors: errors_list
        }
      end
    end
  end
end
