class User
  include MongoMapper::Document

  devise :database_authenticatable, :confirmable, :recoverable, :rememberable, :trackable,
    :validatable, :http_authenticatable

  key :username,    String
  key :company_id,  ObjectId
  key :api_key,     String, :index => true
  key :_type,       String
  timestamps!

  attr_accessor :company_name

  has_many :leads
  has_many :comments
  has_many :tasks
  has_many :accounts
  has_many :contacts
  has_many :activities
  has_many :searches
  has_many :invitations, :as => :inviter, :dependent => :destroy
  has_one :invitation, :as => :invited

  belongs_to :company

  before_validation_on_create :set_api_key, :create_company
  after_create :update_invitation

  validates_presence_of :company

  def invitation_code=( invitation_code )
    if @invitation = Invitation.find_by_code(invitation_code)
      self.company_id = @invitation.inviter.company_id
      self.username = @invitation.email.split('@').first if self.username.blank?
      self.email = @invitation.email if self.email.blank?
      self._type = @invitation.user_type
    end
  end

  def deleted_items_count
    [Lead, Contact, Account, Comment].map do |model|
      model.permitted_for(self).deleted.count
    end.inject {|sum, n| sum += n }
  end

  def full_name
    username.present? ? username : email
  end

  def recent_items
    Activity.all(:conditions => { :user_id => self.id,
                 :action => I18n.locale_around(:en) { Activity.actions.index('Viewed') } },
                 :order => 'updated_at desc', :limit => 5).map(&:subject)
  end

  def tracked_items
    (Lead.tracked_by(self) + Contact.tracked_by(self) + Account.tracked_by(self)).
      sort_by(&:created_at)
  end

  def self.send_tracked_items_mail
    User.all.each do |user|
      UserMailer.deliver_tracked_items_update(user) if user.new_activity?
      user.tracked_items.each do |item|
        item.related_activities.not_notified(user).each do |activity|
          activity.update_attributes :notified_user_ids => (activity.notified_user_ids || []) << user.id
        end
      end
    end
  end

  def new_activity?
    (self.tracked_items.map {|i| i.related_activities.not_notified(self).count }.
      inject {|sum,n| sum += n } || 0) > 0
  end

  def dropbox_email
    "dropbox@#{api_key}.salesflip.com"
  end

protected
  def set_api_key
    self.api_key = UUID.new.generate
  end

  def create_company
    company = Company.new :name => self.company_name
    if company.save
      self.company_id = company.id
    end
  end

  def update_invitation
    @invitation.update_attributes :invited_id => self.id if @invitation
  end
end
