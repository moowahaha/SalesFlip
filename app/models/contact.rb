class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include SphinxIndex

  field :first_name
  field :last_name
  field :access,              :type => Integer
  field :title,               :type => Integer
  field :salutation,          :type => Integer
  field :department
  field :source,              :type => Integer
  field :email
  field :alt_email
  field :phone
  field :mobile
  field :fax
  field :website
  field :linked_in
  field :facebook
  field :twitter
  field :xing
  field :address
  field :born_on,             :type => Date
  field :do_not_call,         :type => Boolean
  field :deleted_at,          :type => Time
  field :identifier,          :type => Integer

  validates_presence_of :user, :last_name
  validates_uniqueness_of :email, :allow_blank => true

  before_validate :set_identifier, :on => :create

  sphinx_index :first_name, :last_name, :department, :email, :alt_email, :phone, :mobile,
    :fax, :website, :linked_in, :facebook, :twitter, :xing, :address

  has_constant :accesses, lambda { I18n.t('access_levels') }
  has_constant :titles, lambda { I18n.t('titles') }
  has_constant :sources,  lambda { I18n.t('lead_sources') }
  has_constant :salutations, lambda { I18n.t('salutations') }

  belongs_to_related :account
  belongs_to_related :user
  belongs_to_related :assignee, :class_name => 'User'
  belongs_to_related :lead

  has_many_related :tasks, :as => :asset, :dependent => :destroy
  has_many_related :comments, :as => :commentable, :dependent => :delete_all
  has_many_related :leads, :dependent => :destroy

  named_scope :for_company, lambda { |company| { :where => { :user_id => company.users.map(&:id) } } }

  def full_name
    "#{first_name} #{last_name}"
  end
  alias :name :full_name

  def listing_name
    "#{last_name}, #{first_name}".strip.gsub(/,$/, '')
  end

  def self.create_for( lead, account )
    contact = account.contacts.build :user => lead.updater_or_user, :first_name => lead.first_name,
      :last_name => lead.last_name, :permission => account.permission,
      :permitted_user_ids => account.permitted_user_ids
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
