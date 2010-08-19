class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  has_many_related :users

  validates_presence_of :name
  validates_uniqueness_of :name
end
