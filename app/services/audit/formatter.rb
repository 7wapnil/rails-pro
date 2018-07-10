module Audit
  class Formatter
    # requires a record to be AuditLog instance
    def format_action(record)
      formatted = "#{record.target} #{record.action}"
      origin_str = format_origin(record)
      formatted += " #{origin_str}" unless origin_str.blank?
      formatted
    end

    private

    def format_origin(record)
      return if record.origin_model.nil?

      origin = record.origin
      origin_model = record.origin_model
      "by #{origin[:kind]} #{origin_model.full_name}, ID #{origin[:id]}"
    end
  end
end
