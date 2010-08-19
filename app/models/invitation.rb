class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include HasConstant::Orm::Mongoid

  field :email
  field :code
  field :user_type,   :type => Integer

  belongs_to_related :invited,  :class_name => 'User'
  belongs_to_related :inviter,  :class_name => 'User'

  validates_presence_of :inviter, :email, :code, :user_type

  before_validation :generate_code, :on => :create
  after_create :send_invitation

  has_constant :user_types, lambda { %w(User Freelancer) }

  named_scope :by_company, lambda { |company| { :where => {
    :inviter_id.in => company.users.map(&:id) } } }

protected
  def generate_code
    self.code = UUID.new.generate if code.blank?
  end

  def send_invitation
    InvitationMailer.invitation(self).deliver
  end
end
