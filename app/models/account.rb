class Account
  include MongoMapper::Document
  include HasConstant
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include FullSearch

  key :user_id,           ObjectId, :index => true, :required => true
  key :assignee_id,       ObjectId, :index => true
  key :name,              String, :required => true, :index => true
  key :email,             String, :index => true
  key :access,            Integer, :index => true
  key :website,           String
  key :phone,             String
  key :fax,               String
  key :billing_address,   String
  key :shipping_address,  String
  key :identifier,        Integer
  key :account_type,      Integer
  timestamps!

  has_constant :accesses, lambda { I18n.t('access_levels') }
  has_constant :account_types, lambda { I18n.t('account_types') }

  belongs_to :user
  belongs_to :assignee, :class_name => 'User'
  has_many :contacts, :dependent => :nullify
  has_many :tasks, :as => :asset, :dependent => :delete_all
  has_many :comments, :as => :commentable, :dependent => :delete_all

  before_create :set_identifier

  named_scope :for_company, lambda { |company| { :conditions => { :user_id => company.users.map(&:id) } } }

  validates_uniqueness_of :email, :allow_blank => true

  search_keys :name, :email, :phone, :website, :fax

  alias :full_name :name

  def self.find_or_create_for( object, name_or_id, options = {} )
    account = Account.find_by_id(Mongo::ObjectID.from_string(name_or_id.to_s))
  rescue Mongo::InvalidObjectID => e
    account = Account.find_by_name(name_or_id)
    account = create_for(object, name_or_id, options) unless account
    account
  end

  def self.create_for( object, name, options = {} )
    if options[:permission] == 'Object'
      permission = object.permission
      permitted = object.permitted_user_ids
    else
      permission = options[:permission]
      permitted = options[:permitted_user_ids]
    end
    account = object.updater_or_user.accounts.create :permission => permission,
      :name => name, :permitted_user_ids => permitted
  end

protected
  def set_identifier
    self.identifier = Identifier.next_account
  end
end
