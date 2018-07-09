module Audit
  class Formatter
    # requires a record to be AuditLog instance
    def format(record)
      formatted = "#{record.target} #{record.action}"
      origin_str = format_origin(record)
      unless origin_str.blank?
        formatted +=" #{origin_str}"
      end
      formatted
    end

    private

    def format_origin(record)
      origin = record.origin
      unless origin.blank?
        "by #{record.origin[:kind]} #{origin.full_name}, ID #{record.origin[:id]}"
      end
    end

  end
end
