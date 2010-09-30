class TasksController < InheritedResources::Base

  has_scope :assigned,              :type => :boolean
  has_scope :completed,             :type => :boolean
  has_scope :incomplete,            :type => :boolean
  has_scope :overdue,               :type => :boolean
  has_scope :due_today,             :type => :boolean
  has_scope :due_tomorrow,          :type => :boolean
  has_scope :due_this_week,         :type => :boolean
  has_scope :due_next_week,         :type => :boolean
  has_scope :due_later,             :type => :boolean
  has_scope :completed_today,       :type => :boolean
  has_scope :completed_yesterday,   :type => :boolean
  has_scope :completed_last_week,   :type => :boolean
  has_scope :completed_this_month,  :type => :boolean
  has_scope :completed_last_month,  :type => :boolean
  has_scope :for do |controller, scope, value|
    scope.for(User.find(BSON::ObjectId.from_string(value)))
  end
  has_scope :assigned_by do |controller, scope, value|
    scope.assigned_by(User.find(value))
  end

  def create
    create! do |success, failure|
      success.html { return_to_or_default tasks_path(:incomplete => true, :for => current_user.id) }
    end
  end

  def update
    update! do |success, failure|
      success.html do
        return_to_or_default tasks_path(:incomplete => true)
        if params[:task] and params[:task][:assignee_id]
          flash[:notice] = I18n.t('task_reassigned', :user => @task.assignee.email)
        end
      end
    end
  end

  def destroy
    destroy! do |success, failure|
      success.html { return_to_or_default tasks_path(:incomplete => true) }
    end
  end

protected
  def build_resource
    @task ||= begin_of_association_chain.tasks.build({ :assignee_id => current_user.id }.
                                                     merge(params[:task] || {}))
    @task.asset_id = params[:asset_id] if params[:asset_id]
    @task.asset_type = params[:asset_type] if params[:asset_type]
    @task
  end

  def collection
    if params[:scopes]
      @tasks = {}
      params[:scopes].keys.map(&:to_sym).each do |scope|
        @tasks[scope] = apply_scopes(Task).asc(:due_at).send(scope)
      end
    else
      @overdue ||= apply_scopes(Task).overdue.asc(:due_at)
      @due_today ||= apply_scopes(Task).due_today.asc(:due_at)
      @due_tomorrow ||= apply_scopes(Task).due_tomorrow.asc(:due_at)
      @due_this_week ||= apply_scopes(Task).due_this_week.asc(:due_at)
      @due_next_week ||= apply_scopes(Task).due_next_week.asc(:due_at)
      @due_later ||= apply_scopes(Task).due_later.asc(:due_at)
    end
  end

  def resource
    @task ||= Task.for(current_user).where(:_id => params[:id]).first
  end

  def begin_of_association_chain
    current_user
  end
end
