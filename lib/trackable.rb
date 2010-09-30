module Trackable
  def self.included( base )
    base.class_eval do
      field :tracker_ids, :type => Array
      named_scope :tracked_by, lambda { |user| { :where => { :tracker_ids => user.id } } }
    end
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def trackers
      unless tracker_ids.nil?
        User.where(:_id.in => tracker_ids.map { |id| BSON::ObjectId.from_string(id.to_s) })
      end
    end

    def tracked_by?( user )
      trackers && trackers.include?(user)
    end

    def tracker_ids=( ids )
      write_attribute :tracker_ids, ids.map { |id| BSON::ObjectId.from_string(id.to_s) } if ids
    end

    def remove_tracker_ids=( ids )
      olds_ids = read_attribute(:tracker_ids) || []
      write_attribute :tracker_ids, olds_ids.map(&:to_s) - ids.map(&:to_s)
    end
  end
end
