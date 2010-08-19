class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include HasConstant::Orm::Mongoid
  include Permission

  field :name
  field :due_at,          :type => Time
  field :category,        :type => Integer
  field :priority,        :type => Integer
  field :completed_at,    :type => Time
  field :deleted_at,      :type => Time

  has_constant :categories, lambda { I18n.t(:task_categories) }

  belongs_to_related :user
  belongs_to_related :asset, :polymorphic => true
  belongs_to_related :assignee, :class_name => 'User'
  belongs_to_related :completed_by, :class_name => 'User'

  has_many_related :activities, :as => :subject, :dependent => :destroy

  validates_presence_of :user, :name, :due_at, :category

  after_create :assign_unassigned_lead

  named_scope :incomplete, :where => { :completed_at => nil }

  def self.for( user )
    any_of({ :user_id => user.id, :assignee_id => user.id }, { :assignee_id => user.id },
           { :user_id => user.id, :assignee_id => nil })
  end

  # '$where' => "this.user_id == '#{user.id}' && this.assignee_id != null && this.assignee_id != '#{user.id}'"
  named_scope :assigned_by, lambda { |user| { :where => {
    :user_id => user.id, :assignee_id.ne => nil, :assignee_id.ne => user.id } } }

  named_scope :pending, :where => { :completed_at => nil, :assignee_id => nil }

  named_scope :assigned, :where => { :assignee_id.ne => nil }

  named_scope :completed, :where => { :completed_at.ne => nil }

  named_scope :overdue, lambda { { :where => { :due_at.lte => Time.zone.now.midnight.utc } } }

  named_scope :due_today, lambda { { :where => {
    :due_at.gt => Time.zone.now.midnight.utc,
    :due_at.lte => Time.zone.now.end_of_day.utc } } }

  named_scope :due_tomorrow, lambda { { :where => {
    :due_at.lte => Time.zone.now.tomorrow.end_of_day.utc,
    :due_at.gte => Time.zone.now.tomorrow.beginning_of_day.utc } } }

  named_scope :due_this_week, lambda { { :where => {
    :due_at.gte => Time.zone.now.tomorrow.end_of_day.utc + 1.day,
    :due_at.lte => Time.zone.now.next_week.utc } } }

  named_scope :due_next_week, lambda { { :where => {
    :due_at.gte => Time.zone.now.next_week.beginning_of_week.utc,
    :due_at.lte => Time.zone.now.next_week.end_of_week } } }

  named_scope :due_later, lambda { { :where => {
    :due_at.gt => Time.zone.now.next_week.end_of_week } } }

  named_scope :completed_today, lambda { { :where => {
    :completed_at.gte => Time.zone.now.midnight.utc,
    :completed_at.lte => Time.zone.now.midnight.tomorrow.utc } } }

  named_scope :completed_yesterday, lambda { { :where => {
    :completed_at.gte => Time.zone.now.midnight.yesterday.utc,
    :completed_at.lte => Time.zone.now.midnight.utc } } }

  named_scope :completed_last_week, lambda { { :where => {
    :completed_at.gte => Time.zone.now.beginning_of_week.utc - 7.days,
    :completed_at.lte => Time.zone.now.beginning_of_week.utc } } }

  named_scope :completed_this_month, lambda { { :where => {
    :completed_at.gte => Time.zone.now.beginning_of_month.utc,
    :completed_at.lte => Time.zone.now.beginning_of_week.utc - 7.days } } }

  named_scope :completed_last_month, lambda { { :where => {
    :completed_at.gte => (Time.zone.now.beginning_of_month.utc - 1.day).beginning_of_month.utc,
    :completed_at.lte => Time.zone.now.beginning_of_month.utc } } }

  before_update :log_reassignment
  after_create  :log_creation
  after_create  :assign_unassigned_lead
  after_update  :log_update
  after_save    :notify_assignee

  def self.daily_email
    (Task.overdue + Task.due_today).flatten.sort_by(&:due_at).group_by(&:user).
      each do |user, tasks|
      TaskMailer.daily_task_summary(user, tasks).deliver
    end
  end

  def self.grouped_by_scope( scopes, options = {} )
    tasks = {}
    scopes.each do |scope|
      if self.scopes.map(&:first).include?(scope.to_sym)
        tasks[scope.to_sym] = (options[:target] || self).send(scope.to_sym)
      end
    end
    tasks
  end

  def completed_by_id=( user_id )
    if user_id and not completed?
      @recently_completed = true
      write_attribute :completed_at, Time.zone.now
      write_attribute :completed_by_id, user_id
    end
  end

  def completed?
    completed_at
  end

  def assignee_id=( assignee_id )
    if !assignee_id.blank? and assignee_id != self.assignee_id and !new_record?
      @reassigned = true
      write_attribute :assignee_id, assignee_id
    end
  end

  def due_at=( due )
    write_attribute :due_at,
      case due
      when 'overdue'
        Time.zone.now.yesterday.end_of_day
      when 'due_today'
        Time.zone.now.end_of_day
      when 'due_tomorrow'
        Time.zone.now.tomorrow.end_of_day
      when 'due_this_week'
        Time.zone.now.end_of_week
      when 'due_next_week'
        Time.zone.now.next_week.end_of_week
      when 'due_later'
        Time.zone.now.end_of_day + 5.years
      else
        if %w(overdue due_today due_tomorrow due_this_week due_next_week due_later).include?(due) and
          !due.is_a?(Time) and Chronic.parse(due)
          Chronic.parse(due)
        else
          due
        end
      end
  end

  def due_at_in_words
    if self.due_at && self.due_at.strftime("%H:%M:%S") == '23:59:59'
      case
      when self.due_at.to_i < Time.zone.now.midnight.to_i
        'overdue'
      when self.due_at.to_i == Time.zone.now.end_of_day.to_i
        'due_today'
      when self.due_at.to_i == Time.zone.now.tomorrow.end_of_day.to_i
        'due_tomorrow'
      when self.due_at.to_i >= (Time.zone.now.tomorrow.end_of_day + 1.day).to_i && self.due_at.to_i <= Time.zone.now.end_of_week.to_i
        'due_this_week'
      when self.due_at.to_i >= Time.zone.now.next_week.beginning_of_week.to_i && self.due_at.to_i <= Time.zone.now.next_week.end_of_week.to_i
        'due_next_week'
      when self.due_at.to_i > Time.zone.now.next_week.end_of_week.to_i
        'due_later'
      end
    elsif self.due_at
      self.due_at.to_s :short
    else
      nil
    end
  end

  def notify_assignee
    TaskMailer.assignment_notification(self).deliver if @reassigned
  end

  def log_creation
    Activity.log(self.user, self, 'Created')
  end

  def log_update
    unless @reassigned
      Activity.log(self.user, self, 'Updated') unless @recently_completed
      Activity.log(self.user, self, 'Completed') if @recently_completed
    end
  end

  def log_reassignment
    Activity.log(self.user, self, 'Re-assigned') if @reassigned and valid?
  end

protected
  def assign_unassigned_lead
    if asset and asset.is_a?(Lead) and asset.assignee.blank?
      asset.update_attributes :assignee => self.user
    end
  end
end
