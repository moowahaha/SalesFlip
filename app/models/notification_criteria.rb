class NotificationCriteria
  include Mongoid::Document
  include HasConstant
  include HasConstant::Orm::Mongoid

  field :model
  field :criteria,  :type => Hash
  field :frequency, :type => Integer
  field :send_at,   :type => Time

  has_constant :frequencies, ['Immediate', 'Daily', 'Weekly']

  embedded_in :user, :inverse_of => :notification_criterias
end
