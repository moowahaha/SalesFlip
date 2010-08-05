class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  has_many_related :users

  validates_uniqueness_of :name
end
