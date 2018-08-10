class DashboardsController < ApplicationController
  def show
  end

  def create
    WebSocket::Client.instance.emit('test', message: params[:message],
                                            name: current_user.full_name)
    flash[:success] = 'Message sent'
    redirect_to dashboard_path
  end
end
