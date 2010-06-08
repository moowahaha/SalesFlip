module Permission
  def self.included( base )
    base.class_eval do
      field :permission,          :type => Integer, :default => 0
      field :permitted_user_ids,  :type => Array

      named_scope :permitted_for, lambda { |user|
        if user.instance_of?(User)
          { :conditions => {
            '$where' => "this.user_id == '#{user.id}' || this.permission == '#{Contact.permissions.index('Public')}' || " +
            "this.assignee_id == '#{user.id}' || " +
            "(this.permission == '#{Contact.permissions.index('Shared')}' && contains(this.permitted_user_ids, '#{user.id}')) || " +
            "(this.permission == '#{Contact.permissions.index('Private')}' && this.assignee_id == '#{user.id}')"
          } }
        else
          { :conditions => {
          '$where' => "this.user_id == '#{user.id}' || " +
            "(this.assignee_id == '#{user.id}' && this.permission == '#{Contact.permissions.index('Public')}') || " +
            "(this.assignee_id == '#{user.id}' && this.permission == '#{Contact.permissions.index('Private')}') || " +
            "(this.permission == '#{Contact.permissions.index('Shared')}' && contains(this.permitted_user_ids, '#{user.id}'))"
        } }
        end
      }

      validates_presence_of :permission
      validate :require_permitted_users

      has_constant :permissions, lambda { I18n.t('permissions') }
    end
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def require_permitted_users
      if I18n.locale_around(:en) { permission_is?('Shared') } and permitted_user_ids.length < 1
        errors.add :permitted_user_ids, I18n.t('activerecord.errors.messages.blank')
      end
    end

    def permitted_for?( user )
      I18n.locale_around(:en) do
        if user.instance_of?(User)
          user_id == user.id || permission == 'Public' || assignee_id == user.id ||
            (permission == 'Shared' && permitted_user_ids.include?(user.id)) ||
            (permission == 'Private' && assignee_id == user.id)
        else
          user_id == user.id || (assignee_id == user.id && permission == 'Public') ||
            (assignee_id == user.id && permission == 'Private') ||
            (permission == 'Shared' && permitted_user_ids.include?(user.id) && assignee_id == user.id)
        end
      end
    end
  end
end
