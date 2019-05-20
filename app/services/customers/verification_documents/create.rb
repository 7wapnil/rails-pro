# frozen_string_literal: true

module Customers
  module VerificationDocuments
    class Create < ApplicationService
      def initialize(kind:, file:, customer:)
        @kind = kind
        @file = file
        @customer = customer
      end

      def call
        return error_response unless document.valid?

        attach_document!
        success_response
      end

      private

      attr_reader :file, :kind, :customer

      def document
        @document ||= Documents::CreateForm.new(document: file)
      end

      def attach_document!
        document = customer.verification_documents.create(kind: kind,
                                                          status: :pending)
        document.document.attach(file)
      end

      def success_response
        { success: true }
      end

      def error_response
        {
          success: false,
          errors: errors
        }
      end

      def errors
        Hash[document.errors.collect { |code, message| [code, message] }]
      end
    end
  end
end
