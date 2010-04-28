class InvitationsController < InheritedResources::Base

  before_filter :freelancer_redirect

  def create
    create! do |success, failure|
      success.html { redirect_to invitations_path }
    end
  end

protected
  def collection
    @invitations ||= Invitation.by_company(current_user.company)
  end

  def build_resource
    @invitation ||= current_user.invitations.build params[:invitation]
  end
end
