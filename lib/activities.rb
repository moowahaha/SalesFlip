module Activities
  def self.included( base )
    base.class_eval do
      has_many_related :activities, :as => :subject, :dependent => :destroy

      after_create  :log_creation
      after_update  :log_update

      belongs_to_related :updater, :class_name => 'User'

      attr_accessor :do_not_log
    end
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def log_creation
      return if self.do_not_log
      Activity.log(self.user, self, 'Created')
      @recently_created = true
    end

    def updater_or_user
      self.updater.nil? ? self.user : self.updater
    end

    def log_update
      return if self.do_not_log
      case
      when @recently_destroyed
        Activity.log(updater_or_user, self, 'Deleted')
      when @recently_restored
        Activity.log(updater_or_user, self, 'Restored')
      else
        Activity.log(updater_or_user, self, 'Updated')
      end
    end

    def related_activities
      conditions = ["(this.subject_type == 'Lead' && this.subject_id == '#{self.id}')"]
      conditions << "((this.subject_type == 'Comment' || this.subject_type == 'Email') && '#{comments.map(&:id)}'.indexOf(this.subject_id) != -1)"
      conditions << "(this.subject_type == 'Task' && '#{tasks.map(&:id)}'.indexOf(this.subject_id) != -1)"
      Activity.where(conditions.join(' || '))
    end
  end
end
