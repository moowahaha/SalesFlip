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

  validates_presence_of :model, :frequency

  def add_criteria( field, type, values )
    self.criteria = {} if self.criteria.blank?
    self.criteria.merge!(field => { "$#{type}" => values })
  end

  def get_criteria( field, type )
    if self.criteria.instance_of?(Hash) and self.criteria[field]
      self.criteria[field]["$#{type}"]
    end
  end

  CRITERIA = '^criteria_([^\s]*)_([^\s]*)'

  def responds_to( method_sym, *arguements, &block )
    if method_sym.to_s =~ /#{CRITERIA}=$/ || method_sym.to_s =~ /#{CRITERIA}$/
      true
    else
      super
    end
  end

protected
  def method_missing( method_sym, *arguements, &block )
    if method_sym.to_s =~ /#{CRITERIA}=$/
      add_criteria($1, $2, *arguements)
    elsif method_sym.to_s =~ /#{CRITERIA}$/
      get_criteria($1, $2)
    else
      super
    end
  end
end
