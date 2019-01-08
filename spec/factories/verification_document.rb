# frozen_string_literal: true

FactoryBot.define do
  factory :verification_document do
    kind   { VerificationDocument::PERSONAL_ID }
    status { VerificationDocument::PENDING }

    customer

    after(:build) do |doc|
      file_path = Rails.root.join(
        'spec', 'support', 'fixtures/files/verification_document_image.jpg'
      )
      doc.document.attach(
        io:           File.open(file_path),
        filename:     'verification_document_image.jpg',
        content_type: 'image/jpeg'
      )
    end
  end
end
