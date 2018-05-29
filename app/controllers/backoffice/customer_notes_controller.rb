module Backoffice
  class CustomerNotesController < BackofficeController
    def create
      note = CustomerNote.new(customer_note_params)

      if note.save
        redirect_to backoffice_customer_path(note.customer)
      else
        # This ugly hack assumes that only thing that can be possible invalid
        # is blank content. Needs to be fixed at some point
        flash[:error] = note.errors.full_messages.first
        redirect_back fallback_location: root_path
      end
    end

    private

    def customer_note_params
      params
        .require(:customer_note)
        .permit(:customer_id, :content)
        .merge(user_id: current_user.id)
    end
  end
end
