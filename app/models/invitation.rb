class Invitation
  include MongoMapper::Document
  include HasConstant

  key :email,       String,   :required => true
  key :inviter_id,  ObjectId
  key :invited_id,  ObjectId
  key :code,        String,   :required => true
  key :user_type,   Integer
  timestamps!

  belongs_to :invited,  :class_name => 'User'
  belongs_to :inviter,  :class_name => 'User'

  validates_presence_of :inviter

  before_validation_on_create :generate_code
  after_create :send_invitation

  has_constant :user_types, lambda { %w(User Freelancer) }

  named_scope :by_company, lambda { |company| { :conditions => {
    :inviter_id => company.users.map(&:id) } } }

protected
  def generate_code
    self.code = UUID.new.generate
  end

  def send_invitation
    InvitationMailer.deliver_invitation(self)
  end
end
