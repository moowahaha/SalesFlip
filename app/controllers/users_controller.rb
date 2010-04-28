class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, :only => [:new, :create]
  skip_before_filter :log_viewed_item
  before_filter :invitation, :only => [:new, :create]
  before_filter :freelancer_redirect, :only => [:index]

  def create
    create! do |success, failure|
      success.html { redirect_to root_path }
    end
  end

  def profile
    @user = current_user
  end

protected
  def invitation
    @invitation ||= Invitation.find_by_code(params[:invitation_code]) if params[:invitation_code]
  end

  def build_resource
    attributes = params[:user] || {}
    attributes.merge!(:invitation_code => invitation.code) if invitation
    @user ||= User.new attributes
  end
end
