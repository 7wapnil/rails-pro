class DashboardsController < ApplicationController
  def show
  end

  def create
    client = WebSocketClient.new
    client.connect
    client.emit('test', message: params[:message],
                        name: current_user.full_name)
    flash[:success] = 'Message sent'
    redirect_to dashboard_path
  end
end
