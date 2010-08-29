class EmailsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    if request.headers['Authorization'] != '20015510-959d-012d-a4ae-001c25a0b06f'
      return head(:unauthorized)
    else
      UserMailer.receive(params[:email][:raw])
      head :ok
    end
  end
end
