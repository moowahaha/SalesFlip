class Alias < ActiveRecord::Base
  validates_presence_of :mail, :destination
end
