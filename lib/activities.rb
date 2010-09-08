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
      @activities ||=
        Activity.any_of({ :subject_type.in => %w(Lead Account Contact), :subject_id => self.id },
                        { :subject_type.in => %w(Comment Email), :subject_id => comments.map(&:id) },
                        { :subject_type => 'Task', :subject_id => tasks.map(&:id) }).desc(:created_at)
      if self.respond_to?(:contacts)
        @activities = @activities.any_of(
          { :subject_type => 'Contact', :subject_id.in => self.contacts.map(&:id) },
          { :subject_type => 'Lead',
            :subject_id.in => self.leads.flatten.map(&:id) },
          { :subject_type => 'Task',
            :subject_id.in => self.contacts.map(&:tasks).flatten.map(&:id) +
            self.contacts.map(&:leads).flatten.map(&:tasks).flatten.map(&:id) },
          { :subject_type.in => %w(Comment Email),
            :subject_id.in => self.contacts.map(&:comments).flatten.map(&:id) +
            self.contacts.map(&:emails).flatten.map(&:id) +
            self.leads.map(&:comments).flatten.map(&:id) +
            self.leads.map(&:emails).flatten.map(&:id) })
      end
      @activities
    end
  end
end
