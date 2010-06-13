require 'test_helper.rb'

class ActivityTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_constant :actions
    should_require_key :user_id

    context 'log' do
      setup do
        @lead = Lead.make(:erich)
        Activity.delete_all
      end

      should 'create a new activity with the supplied user, model and action' do
        Activity.log(@lead.user, @lead, 'Viewed')
        assert_equal 1, Activity.count
        assert Activity.first(:conditions => { :user_id => @lead.user_id, :subject_id => @lead.id,
                              :subject_type => 'Lead', :action => Activity.actions.index('Viewed') })
      end

      should 'create a new activity for "Deleted"' do
        Activity.log(@lead.user, @lead, 'Deleted')
        assert @lead.activities.any? {|a| a.action == 'Deleted' }
      end

      should 'find and update the last activity if action is "Viewed"' do
        Activity.log(@lead.user, @lead, 'Viewed')
        activity = Activity.last(:order => 'created_at')
        updated_at = activity.updated_at
        sleep 1
        activity2 = Activity.log(@lead.user, @lead, 'Viewed')
        assert_equal 1, Activity.count
        assert updated_at != activity2.updated_at
      end

      should 'find and update the last activity if action is "Commented"' do
        Activity.log(@lead.user, @lead, 'Commented')
        activity = Activity.last(:order => 'created_at')
        updated_at = activity.updated_at
        sleep 1
        activity2 = Activity.log(@lead.user, @lead, 'Commented')
        assert_equal 1, Activity.count
        assert updated_at != activity2.updated_at
      end

      should 'find and update the last activity if action is "Updated"' do
        Activity.log(@lead.user, @lead, 'Updated')
        activity = Activity.last(:order => 'created_at')
        updated_at = activity.updated_at
        sleep 1
        activity2 = Activity.log(@lead.user, @lead, 'Updated')
        assert_equal 1, Activity.count
        assert updated_at != activity2.updated_at
      end

      should 'NOT create "Viewed" activity for tasks' do
        task = Task.make(:call_erich)
        Activity.delete_all
        Activity.log(task.user, task, 'Viewed')
        assert_equal 0, Activity.count
      end
    end
  end

  context 'Named Scopes' do
    context 'limit' do
      setup do
        12.times do
          Account.make
        end
      end

      should 'limit the results to the specified length' do
        assert_equal 2, Activity.limit(2).length
        assert_equal 10, Activity.limit(10).length
      end
    end

    context 'already_notified' do
      setup do
        @user = User.make(:annika)
        @lead = Lead.make(:erich)
        @contact = Contact.make(:florian)
        Activity.delete_all
        @activity1 = Activity.log(@user, @lead, 'Created')
        @activity2 = Activity.log(@user, @contact, 'Created')
        @activity2.update_attributes :notified_user_ids => [@user.id]
      end

      should 'return activities where the supplied user has already been notified' do
        assert Activity.already_notified(@user).include?(@activity2)
        assert !Activity.already_notified(@user).include?(@activity)
        assert_equal 1, Activity.already_notified(@user).count
      end
    end

    context 'not_notified' do
      setup do
        @user = User.make(:annika)
        @lead = Lead.make(:erich)
        @contact = Contact.make(:florian)
        Activity.delete_all
        @activity1 = Activity.log(@user, @lead, 'Created')
        @activity2 = Activity.log(@user, @contact, 'Created')
        @activity2.update_attributes :notified_user_ids => [@user.id]
      end

      should 'return activities where the supplied user needs to be notified' do
        assert Activity.not_notified(@user).include?(@activity1)
        assert !Activity.not_notified(@user).include?(@activity2)
        assert_equal 1, Activity.not_notified(@user).count
      end
    end

    context 'not_restored' do
      setup do
        @deleted = Lead.make
        @deleted.destroy
        @restored = Lead.make
        @restored.destroy
        @restored = Lead.find(@restored.id)
        @restored.update_attributes :deleted_at => nil
      end

      should 'only return activities where the subject deleted_at is not nil' do
        assert_equal 1, Activity.action_is('Deleted').not_restored.count
        assert Activity.scoped({}).not_restored.map(&:subject).include?(@deleted)
      end
    end

    context 'visible_to' do
      setup do
        @annika = User.make(:annika)
        @benny = User.make(:benny)
        @contact = Contact.make(:florian, :user => @annika, :permission => 'Private')
        @activity = @contact.activities.first
      end

      should 'NOT return activities where subject permission is private and subject user is not owner' do
        assert !Activity.scoped({}).visible_to(@benny).include?(@activity)
      end

      should 'return activities where subject permission is private and subject user is owner' do
        assert Activity.scoped({}).visible_to(@annika).include?(@activity)
      end

      should 'return activities where subject user is owner' do
        @contact.update_attributes :user_id => @benny.id, :permission => 'Public'
        assert Activity.scoped({}).visible_to(@benny).include?(@activity)
      end

      should 'return activities where subject permission is public' do
        @contact.update_attributes :permission => 'Public'
        assert Activity.scoped({}).visible_to(@benny).include?(@activity)
        assert Activity.scoped({}).visible_to(@annika).include?(@activity)
      end

      should 'return activities where subject permission is shared and user is in subjects permitted user list' do
        @contact.update_attributes :permission => 'Shared', :permitted_user_ids => [@benny.id]
        assert Activity.scoped({}).visible_to(@benny).include?(@activity)
        assert Activity.scoped({}).visible_to(@annika).include?(@activity)
      end

      should 'NOT return activities where subject permission is shared and user is NOT in subjects permitted user list' do
        @contact.update_attributes :permission => 'Shared', :permitted_user_ids => [@annika.id]
        assert Activity.scoped({}).visible_to(@annika).include?(@activity)
        assert !Activity.scoped({}).visible_to(@benny).include?(@activity)
      end
    end
  end

  context 'Instance' do
    setup do
      @activity = Activity.make_unsaved(:viewed_erich)
    end

    should 'be valid' do
      assert @activity.valid?
    end

    should 'be invalid without subject' do
      @activity.subject = nil
      assert !@activity.valid?
      assert @activity.errors[:subject]
    end
  end
end
