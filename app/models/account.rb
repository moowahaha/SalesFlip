class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include HasConstant::Orm::Mongoid
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include Sunspot::Mongoid

  field :name
  field :email
  field :access,            :type => Integer
  field :website
  field :phone
  field :fax
  field :billing_address
  field :shipping_address
  field :identifier,        :type => Integer
  field :account_type,      :type => Integer

  has_constant :accesses, lambda { I18n.t('access_levels') }
  has_constant :account_types, lambda { I18n.t('account_types') }

  belongs_to_related :user
  belongs_to_related :assignee, :class_name => 'User'
  has_many_related :contacts, :dependent => :nullify
  has_many_related :tasks, :as => :asset
  has_many_related :comments, :as => :commentable

  validates_presence_of :user, :name

  before_create :set_identifier

  named_scope :for_company, lambda { |company| { :where => { :user_id.in => company.users.map(&:id) } } }

  validates_uniqueness_of :email, :allow_blank => true

  searchable do
    text :name, :email, :phone, :website, :fax
  end

  def self.exportable_fields
    fields.map(&:first).sort.delete_if do |f|
      f.match(/access|permission|permitted_user_ids|tracker_ids/)
    end
  end

  def leads
    @leads ||= contacts.map(&:leads).flatten
  end

  alias :full_name :name

  def website=( website )
    website = "http://#{website}" if !website.nil? and !website.match(/^http:\/\//)
    write_attribute :website, website
  end

  def self.find_or_create_for( object, name_or_id, options = {} )
    account = Account.find(BSON::ObjectID.from_string(name_or_id.to_s))
  rescue BSON::InvalidObjectID => e
    account = Account.first(:conditions => { :name => name_or_id })
    account = create_for(object, name_or_id, options) unless account
    account
  end

  def self.create_for( object, name, options = {} )
    if options[:permission] == 'Object'
      permission = object.permission
      permitted = object.permitted_user_ids
    else
      permission = options[:permission] || 0
      permitted = options[:permitted_user_ids]
    end
    account = object.updater_or_user.accounts.create :permission => permission,
      :name => name, :permitted_user_ids => permitted
  end

  def deliminated( deliminator, fields )
    fields.map { |field| self.send(field) }.join(deliminator)
  end

protected
  def set_identifier
    self.identifier = Identifier.next_account
  end
end
