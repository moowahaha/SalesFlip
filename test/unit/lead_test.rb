require 'test_helper.rb'

class LeadTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :city, :postal_code, :country, :job_title, :department, :identifier
    should_have_constant :titles, :statuses, :sources, :salutations, :permissions
    should_act_as_paranoid
    should_be_trackable
    should_belong_to :user, :assignee, :contact
    should_have_many :comments, :tasks, :activities
  end

  context 'Named Scopes' do

    context 'for_company' do
      setup do
        @lead = Lead.make(:erich)
        @lead2 = Lead.make(:markus)
      end

      should 'only return leads for the supplied company' do
        assert_equal [@lead], Lead.for_company(@lead.user.company).to_a
      end
    end

    context 'unassigned' do
      setup do
        @user = User.make(:annika)
        @assigned = Lead.make(:erich, :assignee => @user)
        @unassigned = Lead.make(:markus, :assignee => nil)
      end

      should 'return all unassigned leads' do
        assert_equal [@unassigned], Lead.unassigned
      end
    end

    context 'assigned_to' do
      setup do
        @user = User.make(:annika)
        @benny = User.make(:benny)
        @mine = Lead.make(:erich, :assignee => @user)
        @not_mine = Lead.make(:markus, :assignee => @benny)
      end

      should 'return all leads assigned to the supplied user' do
        assert_equal [@mine], Lead.assigned_to(@user.id)
        assert_equal [@not_mine], Lead.assigned_to(@benny.id)
      end
    end

    context 'tracked_by' do
      setup do
        @user = User.make(:annika)
        @tracked = Lead.make(:erich, :tracker_ids => [@user.id])
        @untracked = Lead.make(:markus)
      end

      should 'return leads which are tracked by the supplied user' do
        assert_equal 1, Lead.tracked_by(@user).count
        assert_equal [@tracked], Lead.tracked_by(@user)
        @tracked.update_attributes :tracker_ids => [User.make(:benny).id]
        assert_equal 0, Lead.tracked_by(@user).count
      end
    end

    context 'with_status' do
      setup do
        @new = Lead.make(:erich)
        @rejected = Lead.make(:markus)
      end

      should 'return leads with any of the supplied statuses' do
        assert_equal [@new], Lead.with_status('New').to_a
        assert_equal [@rejected], Lead.with_status('Rejected').to_a
        assert Lead.with_status(['New', 'Rejected']).include?(@new)
        assert Lead.with_status(['New', 'Rejected']).include?(@rejected)
        assert_equal 2, Lead.with_status(['New', 'Rejected']).count
      end
    end

    context 'not_deleted' do
      setup do
        @new = Lead.make(:erich)
        @rejected = Lead.make(:markus)
        @deleted = Lead.make(:kerstin)
      end

      should 'return all leads which are not deleted' do
        assert_equal 2, Lead.not_deleted.count
        assert !Lead.not_deleted.include?(@deleted)
      end
    end

    context 'permitted_for' do
      setup do
        @erich = Lead.make(:erich, :permission => 'Public')
        @markus = Lead.make(:markus, :permission => 'Public')
      end

      should 'return all public leads' do
        assert Lead.permitted_for(@erich.user).include?(@erich)
        assert Lead.permitted_for(@erich.user).include?(@markus)
      end

      should 'return all leads belonging to the user' do
        @erich.update_attributes :permission => 'Private'
        assert Lead.permitted_for(@erich.user).include?(@erich)
      end

      should 'NOT return private leads belonging to another user' do
        @markus.update_attributes :permission => 'Private'
        assert !Lead.permitted_for(@erich.user).include?(@markus)
      end

      should 'return private leads when assigned to this user' do
        @markus.update_attributes :permission => 'Private', :assignee => @erich.user
        assert Lead.permitted_for(@erich.user).include?(@markus)
      end

      should 'return shared leads where the user is in the permitted user list' do
        @markus.update_attributes :permission => 'Shared', :permitted_user_ids => [@markus.user.id, @erich.user.id]
        assert Lead.permitted_for(@erich.user).include?(@markus)
      end

      should 'NOT return shared leads where the user is not in the permitted user list' do
        @markus.update_attributes :permission => 'Shared', :permitted_user_ids => [@markus.user.id]
        assert !Lead.permitted_for(@erich.user).include?(@markus)
      end

      context 'when freelancer' do
        setup do
          @freelancer = Freelancer.make
        end

        should 'not return all public leads' do
          assert Lead.permitted_for(@freelancer).blank?
        end

        should 'return all leads belonging to the user' do
          @erich.update_attributes :user_id => @freelancer.id, :permission => 'Private'
          assert Lead.permitted_for(@freelancer).include?(@erich)
        end

        should 'NOT return private leads belonging to another user' do
          @markus.update_attributes :permission => 'Private'
          assert Lead.permitted_for(@freelancer).blank?
        end

        should 'return shared leads where the user is in the permitted user list' do
          @markus.update_attributes :permission => 'Shared', :permitted_user_ids => [@markus.user_id, @freelancer.id]
          assert Lead.permitted_for(@freelancer).include?(@markus)
        end

        should 'NOT return shared leads where the user is not in the permitted user list' do
          @markus.update_attributes :permission => 'Shared', :permitted_user_ids => [@markus.user_id]
          assert !Lead.permitted_for(@erich.user).include?(@markus)
        end
      end
    end
  end

  context 'Instance' do
    setup do
      @lead = Lead.make_unsaved(:erich, :user => User.make)
      @user = User.make(:benny)
    end

    should 'be assigned an identifier on creation' do
      assert @lead.identifier.nil?
      @lead.save!
      assert @lead.identifier
    end

    should 'be assigned consecutive identifiers' do
      @lead.save!
      assert_equal 1, @lead.identifier
      @lead2 = Lead.make_unsaved
      assert @lead2.identifier.nil?
      @lead2.save!
      assert_equal 2, @lead2.identifier
    end

    context 'changing the assignee' do
      should 'notify assignee' do
        @lead.save!
        ActionMailer::Base.deliveries.clear
        @lead.update_attributes :assignee_id => @user.id
        assert_sent_email do |email|
          email.to.include?(@user.email)
        end
      end

      should 'not notify assignee if do_not_notify is set' do
        @lead.save!
        ActionMailer::Base.deliveries.clear
        @lead.update_attributes :assignee_id => @user.id, :do_not_notify => true
        assert_equal 0, ActionMailer::Base.deliveries.length
      end

      should 'not try to send an email if the assignee is blank' do
        @lead.assignee_id = @user.id
        @lead.save!
        ActionMailer::Base.deliveries.clear
        @lead.update_attributes :assignee_id => nil
        assert_equal 0, ActionMailer::Base.deliveries.length
      end

      should 'not notify the assignee if the lead is a new record' do
        ActionMailer::Base.deliveries.clear
        @lead.assignee_id = @user.id
        @lead.save!
        assert_equal 0, ActionMailer::Base.deliveries.length
      end

      should 'set the assignee_id' do
        @lead.assignee_id = @user.id
        @lead.save!
        assert_equal @lead.assignee, @user
      end
    end

    context 'activity logging' do
      setup do
        @lead.save!
        @lead.reload
      end

      should 'not log a "created" activity when do_not_log is set' do
        lead = Lead.make(:erich, :do_not_log => true)
        assert_equal 0, lead.activities.count
      end

      should 'log an activity when created' do
        assert_equal 1, @lead.activities.count
        assert @lead.activities.any? {|a| a.action == 'Created' }
      end

      should 'log an activity when updated' do
        @lead = Lead.find(@lead.id)
        @lead.update_attributes :first_name => 'test'
        assert @lead.activities.any? {|a| a.action == 'Updated' }
      end

      should 'not log an "updated" activity when do_not_log is set' do
        lead = Lead.make(:erich, :do_not_log => true)
        lead.update_attributes :do_not_log => true
        assert_equal 0, lead.activities.count
      end

      should 'log an activity when destroyed' do
        @lead = Lead.find(@lead.id)
        @lead.destroy
        assert @lead.activities.any? {|a| a.action == 'Deleted' }
      end

      should 'log an activity when converted' do
        @lead = Lead.find(@lead.id)
        @lead.promote!('A new company')
        assert @lead.activities.any? {|a| a.action == 'Converted' }
      end

      should 'not log an update activity when converted' do
        @lead = Lead.find(@lead.id)
        @lead.promote!('A company')
        assert !@lead.activities.any? {|a| a.action == 'Updated' }
      end

      should 'log an activity when rejected' do
        @lead = Lead.find(@lead.id)
        @lead.reject!
        assert @lead.activities.any? {|a| a.action == 'Rejected' }
      end

      should 'not log an update activity when rejected' do
        @lead = Lead.find(@lead.id)
        @lead.reject!
        assert !@lead.activities.any? {|a| a.action == 'Updated' }
      end

      should 'log an activity when restored' do
        @lead.destroy
        @lead = Lead.find(@lead.id)
        @lead.update_attributes :deleted_at => nil
        assert @lead.activities.any? {|a| a.action == 'Restored' }
      end

      should 'have related activities' do
        @lead.comments.create! :subject => 'afefa', :text => 'asfewfewa', :user => @lead.user
        assert @lead.related_activities.include?(@lead.comments.first.activities.first)
      end
    end

    context 'promote!' do
      setup do
        @lead.save!
      end

      should 'create a new account and contact when a new account is specified' do
        @lead.promote!('Super duper company')
        assert account = Account.first(:conditions => { :name => 'Super duper company' })
        assert account.contacts.any? {|c| c.first_name == @lead.first_name &&
          c.last_name == @lead.last_name }
      end

      should 'change the lead status to "converted"' do
        @lead.promote!('A company')
        assert @lead.status_is?('Converted')
      end

      should 'assign lead to contact' do
        @lead.promote!('company name')
        assert Account.first(:conditions => { :name => 'company name' }).contacts.first.leads.include?(@lead)
        assert_equal @lead.reload.contact, Account.first(:conditions => { :name => 'company name' }).contacts.first
      end

      should 'be able to specify a "Private" permission level' do
        @lead.promote!('A company', :permission => 'Private')
        assert_equal 'Private', Account.first.permission
        assert_equal 'Private', Contact.first.permission
      end

      should 'be able to specify a "Shared" permission level' do
        @lead.promote!('A company', :permission => 'Shared', :permitted_user_ids => [@lead.user_id])
        assert_equal 'Shared', Account.first.permission
        assert_equal [@lead.user_id], Account.first.permitted_user_ids
        assert_equal 'Shared', Contact.first.permission
        assert_equal [@lead.user_id], Contact.first.permitted_user_ids
      end

      should 'be able to use leads permission level' do
        @lead.update_attributes :permission => 'Shared', :permitted_user_ids => [@lead.user_id]
        @lead.promote!('A company', :permission => 'Object')
        assert_equal @lead.permission, Account.first.permission
        assert_equal @lead.permitted_user_ids, Account.first.permitted_user_ids
        assert_equal @lead.permission, Contact.first.permission
        assert_equal @lead.permitted_user_ids, Contact.first.permitted_user_ids
      end

      should 'return an invalid account without an account name' do
        account, contact = @lead.promote!('')
        assert !account.errors.blank?
      end

      should 'not create a contact when account is invalid' do
        @lead.promote!('')
        assert_equal 0, Contact.count
      end

      should 'not convert lead when account is invalid' do
        @lead.promote!('')
        assert_equal 'New', @lead.reload.status
      end

      should 'return existing contact and account if a contact already exists with the same email' do
        @lead.update_attributes :email => 'florian.behn@careermee.com'
        @contact = Contact.make(:florian, :email => 'florian.behn@careermee.com')
        @lead.promote!('')
        assert_equal 1, Contact.count
        assert_equal 'Converted', @lead.reload.status
      end

      should 'save the lead if additional attributes where added before callling promote' do
        @lead.updater_id = @user.id
        @lead.promote!('A company', :permission => 'Object')
        assert_equal @user.id, @lead.reload.updater_id
      end
    end

    should 'require last name' do
      @lead.last_name = nil
      assert !@lead.valid?
      assert @lead.errors[:last_name]
    end

    should 'require user id' do
      @lead.user = nil
      assert !@lead.valid?
      assert @lead.errors[:user]
    end

    should 'require at least one permitted user if permission is "Shared"' do
      @lead.permission = 'Shared'
      assert !@lead.valid?
      assert @lead.errors[:permitted_user_ids]
    end

    should 'be valid' do
      assert @lead.valid?
    end

    should 'have full_name' do
      assert_equal 'Erich Feldmeier', @lead.full_name
    end

    should 'alias full_name to name' do
      assert_equal @lead.name, @lead.full_name
    end

    should 'start with status "New"' do
      @lead.save
      assert_equal 'New', @lead.status
    end

    should 'start with different status if one is specified' do
      @lead.status = 'Rejected'
      @lead.save
      assert_equal 'Rejected', @lead.status
    end
  end
end
