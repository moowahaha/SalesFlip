class ContactsController < InheritedResources::Base
  before_filter :merge_updater_id, :only => [ :update ]

  respond_to :html
  respond_to :xml

  def index
    index! do |format|
      format.html
      format.xml
      format.csv do
        fields = params[:fields] || Contact.exportable_fields
        data = "#{fields.join(params[:deliminator] || '|')}\n"
        data = contacts.map { |c| c.deliminated(params[:deliminator] || '|', fields) }.join("\n")
        send_data data, :type => 'text/csv'
      end
    end
  end

  def create
    create! do |success, failure|
      success.xml { head :ok }
    end
  end

  def destroy
    @contact.updater_id = current_user.id
    @contact.destroy
    redirect_to contacts_path
  end

protected
  def contacts
    Contact.permitted_for(current_user).not_deleted.asc(:last_name).
      for_company(current_user.company)
  end

  def collection
    @page ||= params[:page] || 1
    @per_page = 10
    @contacts ||= hook(:contacts_collection, self,
                       :pages => { :page => @page, :per_page => @per_page }).last
    @contacts ||= contacts.paginate(:per_page => @per_page, :page => @page)
  end

  def resource
    @contact ||= hook(:contacts_resource, self).last
    @contact ||= Contact.for_company(current_user.company).permitted_for(current_user).
      where(:_id => params[:id]).first
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
