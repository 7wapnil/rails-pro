module Backoffice
  class CustomerNotesController < BackofficeController
    def create
      note = CustomerNote.new(customer_note_params)

      if note.save
        redirect_to notes_backoffice_customer_path(note.customer)
      else
        flash[:error] = note.errors.full_messages
        redirect_back fallback_location: root_path
      end
    end

    private

    def customer_note_params
      params
        .require(:customer_note)
        .permit(:customer_id, :content)
        .merge(user_id: current_user.id)
        .merge(origin_params)
    end
  end
end
