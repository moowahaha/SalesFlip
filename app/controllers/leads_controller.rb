class LeadsController < InheritedResources::Base
  before_filter :resource, :only => [:convert, :promote, :reject]

  respond_to :html
  respond_to :xml, :only => [ :new, :create, :index, :show ]

  has_scope :with_status, :type => :array
  has_scope :unassigned, :type => :boolean
  has_scope :assigned_to
  has_scope :source_is, :type => :array

  def new
    @lead = build_resource
    @lead.assignee_id = current_user.id
  end

  def create
    create! do |success, failure|
      success.html { return_to_or_default leads_path }
    end
  end

  def update
    params[:lead].merge!(:updater_id => current_user.id)
    update! do |success, failure|
      success.html { return_to_or_default leads_path }
    end
  end

  def destroy
    resource
    @lead.updater_id = current_user.id
    @lead.destroy
    redirect_to leads_path
  end

  def convert
    @account = current_user.accounts.new(:name => @lead.company)
    @contact = Contact.first(:conditions => { :email => @lead.email }) if @lead.email
  end

  def promote
    @lead.updater_id = current_user.id
    @account, @contact = @lead.promote!(
      params[:account_id].blank? ? params[:account_name] : params[:account_id])
    if @account.errors.blank? and @contact.errors.blank?
      redirect_to account_path(@account)
    else
      render :action => :convert
    end
  end

  def reject
    @lead.updater_id = current_user.id
    @lead.reject!
    redirect_to leads_path
  end

protected
  def collection
    @leads ||= apply_scopes(Lead).for_company(current_user.company).not_deleted.
      permitted_for(current_user).order_by([[:status, :asc], [:created_at, :desc]]).
      paginate(:per_page => 10, :page => params[:page] || 1)
  end

  def resource
    @lead ||= Lead.for_company(current_user.company).permitted_for(current_user).
      where(:_id => BSON::ObjectID.from_string(params[:id])).first
  end

  def begin_of_association_chain
    current_user
  end

  def build_resource
    @lead ||= Lead.new({ :updater => current_user, :user => current_user }.merge!(params[:lead] || {}))
  end
end
