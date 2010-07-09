class ContactsController < InheritedResources::Base
  before_filter :merge_updater_id, :only => [:update]

  respond_to :html
  respond_to :xml

  def create
    create! do |success, failure|
      success.xml { head :ok }
    end
  end

  def destroy
    resource
    @contact.updater_id = current_user.id
    @contact.destroy
    redirect_to contacts_path
  end

protected
  def collection
    @contacts ||= Contact.permitted_for(current_user).not_deleted.order_by([:last_name, :asc]).
      for_company(current_user.company).paginate(:per_page => 10, :page => params[:page] || 1)
  end

  def resource
    @contact ||= Contact.for_company(current_user.company).permitted_for(current_user).
      find(params[:id])
  end

  def begin_of_association_chain
    current_user
  end

  def merge_updater_id
    params[:contact].merge!(:updater_id => current_user.id) if params[:contact]
  end

  def build_resource
    @contact ||= begin_of_association_chain.contacts.build({ :assignee_id => current_user.id }.
                                                           merge(params[:contact] || {}))
  end
end
