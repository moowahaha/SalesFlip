class Lead
  include MongoMapper::Document
  include HasConstant
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include FullSearch

  key :user_id,       ObjectId, :required => true, :index => true
  key :assignee_id,   ObjectId, :index => true
  key :first_name,    String
  key :last_name,     String, :required => true
  key :email,         String
  key :phone,         String
  key :status,        Integer
  key :source,        Integer
  key :rating,        Integer
  key :campaign_id,   ObjectId, :index => true
  key :notes,         String

  key :title,         Integer
  key :salutation,    Integer
  key :company,       String
  key :job_title,     String
  key :department,    String
  key :alternative_email, String
  key :mobile,        String
  key :address,       String
  key :city,          String
  key :postal_code,   String
  key :country,       String
  key :referred_by,   String
  key :do_not_call,   Boolean

  key :website,       String
  key :twitter,       String
  key :linked_in,     String
  key :facebook,      String
  key :xing,          String
  key :contact_id,    ObjectId
  key :identifier,    Integer
  timestamps!

  search_keys :first_name, :last_name, :email, :phone, :notes, :company, :alternative_email,
    :mobile, :address, :referred_by, :website, :twitter, :linked_in, :facebook, :xing

  attr_accessor :do_not_notify

  belongs_to :user
  belongs_to :assignee, :class_name => 'User'
  belongs_to :contact
  has_many :comments, :as => :commentable, :dependent => :delete_all
  has_many :tasks, :as => :asset, :dependent => :delete_all

  before_validation_on_create :set_initial_state
  before_create :set_identifier
  after_save :notify_assignee, :unless => :do_not_notify

  has_constant :titles, lambda { I18n.t('titles') }
  has_constant :statuses, lambda { I18n.t('lead_statuses') }
  has_constant :sources, lambda { I18n.t('lead_sources') }
  has_constant :salutations, lambda { I18n.t('salutations') }

  named_scope :with_status, lambda { |statuses| { :conditions => {
    :status => statuses.map {|status| Lead.statuses.index(status) } } } }
  named_scope :unassigned, :conditions => { :assignee_id => nil }
  named_scope :assigned_to, lambda { |user_id| { :conditions => { :assignee_id => user_id } } }
  named_scope :for_company, lambda { |company| { :conditions => { :user_id => company.users.map(&:id) } } }

  def full_name
    "#{first_name} #{last_name}"
  end
  alias :name :full_name

  def promote!( account_name, options = {} )
    @recently_converted = true
    if email and (contact = Contact.find_by_email(email))
      I18n.locale_around(:en) { update_attributes :status => 'Converted', :contact_id => contact.id }
    else
      account = Account.find_or_create_for(self, account_name, options)
      contact = Contact.create_for(self, account)
      if [account, contact].all?(&:valid?)
        I18n.locale_around(:en) { update_attributes :status => 'Converted', :contact_id => contact.id }
      end
    end
    return account || contact.account, contact
  end

  def reject!
    @recently_rejected = true
    I18n.locale_around(:en) { update_attributes :status => 'Rejected' }
  end

  def assignee_id=( assignee_id )
    @reassigned = assignee_id unless new_record?
    self[:assignee_id] = assignee_id
  end

protected
  def notify_assignee
    UserMailer.deliver_lead_assignment_notification(self) if @reassigned and not assignee.blank?
  end

  def set_initial_state
    I18n.locale_around(:en) { self.status = 'New' unless self.status }
  end

  def log_update
    return if @do_not_log
    case
    when @recently_converted then Activity.log(updater_or_user, self, 'Converted')
    when @recently_rejected then Activity.log(updater_or_user, self, 'Rejected')
    when @recently_destroyed then Activity.log(updater_or_user, self, 'Deleted')
    when @recently_restored then Activity.log(updater_or_user, self, 'Restored')
    else
      Activity.log(updater_or_user, self, 'Updated')
    end
  end

  def set_identifier
    self.identifier = Identifier.next_lead
  end
end
