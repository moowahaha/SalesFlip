class ContactsController < InheritedResources::Base
  before_filter :merge_updater_id, :only => [ :update ]

  respond_to :html
  respond_to :xml

  has_scope :unassigned, :type => :boolean
  has_scope :assigned_to
  has_scope :source_is

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
      success.html { return_to_or_default contact_path(@contact) }
    end
  end

  def destroy
    @contact.updater_id = current_user.id
    @contact.destroy
    redirect_to contacts_path
  end

protected
  def contacts
    apply_scopes(Contact).permitted_for(current_user).not_deleted.asc(:last_name).
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
    attributes = { :assignee_id => current_user.id }.merge(params[:contact] || {})
    attributes.merge!(:account => account) if account
    @contact ||= begin_of_association_chain.contacts.build attributes
  end

  def account
    @account ||= Account.find(params[:account_id]) if params[:account_id]
  end
end
