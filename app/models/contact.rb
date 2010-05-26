class Contact
  include MongoMapper::Document
  include HasConstant
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include FullSearch

  key :account_id,          ObjectId, :index => true
  key :user_id,             ObjectId, :required => true, :index => true
  key :lead_id,             ObjectId, :index => true
  key :assignee_id,         ObjectId, :index => true
  key :first_name,          String
  key :last_name,           String, :required => true
  key :access,              Integer
  key :title,               Integer
  key :salutation,          Integer
  key :department,          String
  key :source,              Integer
  key :email,               String
  key :alt_email,           String
  key :phone,               String
  key :mobile,              String
  key :fax,                 String
  key :website,             String
  key :linked_in,           String
  key :facebook,            String
  key :twitter,             String
  key :xing,                String
  key :address,             String
  key :born_on,             Date
  key :do_not_call,         Boolean
  key :deleted_at,          Time
  key :identifier,          Integer
  key :city,                String
  key :country,             String
  key :postal_code,         String
  key :job_title,           String
  timestamps!

  validates_uniqueness_of :email, :allow_blank => true

  before_create :set_identifier

  search_keys :first_name, :last_name, :department, :email, :alt_email, :phone, :mobile,
    :fax, :website, :linked_in, :facebook, :twitter, :xing, :address

  has_constant :accesses, lambda { I18n.t('access_levels') }
  has_constant :titles, lambda { I18n.t('titles') }
  has_constant :sources,  lambda { I18n.t('lead_sources') }
  has_constant :salutations, lambda { I18n.t('salutations') }

  belongs_to :account
  belongs_to :user
  belongs_to :assignee, :class_name => 'User'
  belongs_to :lead

  has_many :tasks, :as => :asset, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :delete_all
  has_many :leads, :dependent => :delete_all

  named_scope :for_company, lambda { |company| { :conditions => { :user_id => company.users.map(&:id) } } }

  def full_name
    "#{first_name} #{last_name}"
  end
  alias :name :full_name

  def listing_name
    "#{last_name}, #{first_name}".strip.gsub(/,$/, '')
  end

  def self.create_for( lead, account )
    contact = account.contacts.build :user => lead.updater_or_user, :permission => account.permission,
      :permitted_user_ids => account.permitted_user_ids
    Lead.keys.map(&:first).delete_if do |k|
      %w(identifier _id user_id permission permitted_user_ids _sphinx_id created_at updated_at deleted_at tracker_ids updater_id).
        include?(k)
    end.each do |key|
      if contact.keys.map(&:first).include?(key)
        contact.send("#{key}=", lead.send(key))
      end
    end
    if account.valid? and contact.valid?
      contact.save
      contact.leads << lead
    end
    contact
  end

protected
  def set_identifier
    self.identifier = Identifier.next_contact
  end
end
