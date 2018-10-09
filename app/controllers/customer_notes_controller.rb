class CustomerNotesController < ApplicationController
  def create
    note = CustomerNote.new(customer_note_params)

    if note.save
      current_user.log_event :note_created, note, note.customer
      redirect_to notes_customer_path(note.customer)
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
  end
end
