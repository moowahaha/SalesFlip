class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include HasConstant::Orm::Mongoid
  include ParanoidDelete
  include Permission
  include Trackable
  include Activities
  include Sunspot::Mongoid

  field :first_name
  field :last_name
  field :full_name
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
  field :city
  field :country
  field :postal_code
  field :job_title

  validates_presence_of :user, :last_name
  validates_uniqueness_of :email, :allow_blank => true

  before_create :set_identifier
  before_save   :set_full_name

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
  has_many_related :emails, :as => :commentable, :dependent => :delete_all

  named_scope :for_company, lambda { |company| {
    :where => { :user_id.in => company.users.map(&:id) } } }
  named_scope :name_like, lambda { |name| { :where => { :full_name => /#{name}/i } } }

  searchable do
    text :first_name, :last_name, :department, :email, :alt_email, :phone, :mobile,
      :fax, :website, :linked_in, :facebook, :twitter, :xing, :address
  end

  def self.assigned_to( user_id )
    user_id = BSON::ObjectId.from_string(user_id) if user_id.is_a?(String)
    any_of({ :assignee_id => user_id }, { :user_id => user_id, :assignee_id => nil })
  end

  def self.exportable_fields
    fields.map(&:first).sort.delete_if do |f|
      f.match(/access|permission|permitted_user_ids|tracker_ids/)
    end
  end

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
    Lead.fields.map(&:first).delete_if do |k|
      %w(identifier _id user_id permission permitted_user_ids _sphinx_id created_at updated_at deleted_at tracker_ids updater_id).
        include?(k)
    end.each do |key|
      if contact.fields.map(&:first).include?(key)
        contact.send("#{key}=", lead.send(key))
      end
    end
    if account.valid? and contact.valid?
      contact.save
      contact.leads << lead
    end
    contact
  end

  def deliminated( deliminator, fields )
    fields.map { |field| self.send(field) }.join(deliminator)
  end

protected
  def set_identifier
    self.identifier = Identifier.next_contact
  end

  def set_full_name
    write_attribute :full_name, "#{first_name} #{last_name}"
  end
end
