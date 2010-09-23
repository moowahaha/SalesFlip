class AccountsController < InheritedResources::Base
  before_filter :merge_updater_id, :only => [ :update ]
  before_filter :parent_account, :only => [ :new ]
  before_filter :similarity_check, :only => [ :create ]

  respond_to :html
  respond_to :xml

  def index
    index! do |format|
      format.html
      format.xml
      format.csv do
        fields = params[:fields] || Account.exportable_fields
        data = "#{fields.join(params[:deliminator] || '|')}\n"
        data += accounts.map { |a| a.deliminated(params[:deliminator] || '|', fields) }.join("\n")
        send_data data, :type => 'text/csv'
      end
    end
  end

  def create
    create! do |success, failure|
      success.html { return_to_or_default account_path(@account) }
      success.xml { head :ok }
    end
  end

  def update
    update! do |success, failure|
      success.html { return_to_or_default account_path(@account) }
    end
  end

  def destroy
    resource
    @account.updater_id = current_user.id
    @account.destroy
    redirect_to accounts_path
  end

protected
  def accounts
    @accounts = Account.for_company(current_user.company).permitted_for(current_user).
      not_deleted.asc(:name)
  end

  def collection
    @page = params[:page] || 1
    @per_page = 10
    @accounts ||= hook(:accounts_collection, self,
                       :pages => { :page => @page, :per_page => @per_page }).last
    @accounts ||= accounts.paginate(:per_page => @per_page, :page => @page)
  end

  def resource
    @account ||= hook(:accounts_resource, self).last
    @account ||= Account.for_company(current_user.company).permitted_for(current_user).
      where(:_id => params[:id]).first
  end

  def begin_of_association_chain
    current_user
  end

  def merge_updater_id
    params[:account].merge!(:updater_id => current_user.id) if params[:account]
  end

  def build_resource
    @account ||= begin_of_association_chain.accounts.build({ :assignee_id => current_user.id }.
                                                           merge(params[:account] || {}))
  end

  def parent_account
    @parent_account ||= Account.find(params[:account_id]) if params[:account_id]
  end

  def similarity_check
    return if params[:similarity_off]
    build_resource
    @similar_accounts ||= Account.for_company(current_user.company).similar_accounts(@account.name)
    if @similar_accounts.any?
      render :action => :did_you_mean
    end
  end
end
