require 'test_helper.rb'

class UserTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :company_id, :_type
    should_require_key :email, :company
    should_belong_to :company
    should_have_instance_methods :company_name=, :company_name
    should_have_many :invitations, :leads, :comments, :tasks, :accounts, :contacts, :activities,
      :searches

    context 'send_tracked_items_mail' do
      setup do
        @user = User.make(:annika)
        @benny = User.make(:benny)
        @lead = Lead.make(:erich, :user => @user, :tracker_ids => [@benny.id])
        @comment = @lead.comments.create! :user => @user, :subject => 'a comment',
          :text => 'This is a good lead'
        @email = Email.create! :user => @benny, :subject => 'an offer',
          :text => 'Here is your offer', :commentable => @lead, :from => 'test@test.com',
          :received_at => Time.zone.now
        @attachment = @email.attachments.create! :subject => @email,
          :attachment => File.open('test/upload-files/erich_offer.pdf')
        @task = @lead.tasks.create! :name => 'Call this guy', :due_at => 'due_today',
          :category => 'Call', :user => @user
        ActionMailer::Base.deliveries.clear
      end

      should 'should add users id to notified_users list of all actions which were emailed' do
        User.send_tracked_items_mail
        assert @lead.related_activities.all? {|a| a.notified_user_ids.include?(@benny.id) }
      end

      should 'send tracked items email with all new activities included' do
        User.send_tracked_items_mail
        assert_sent_email do |email|
          email.body =~ /#{@lead.name}/ && email.body =~ /#{@comment.text}/ &&
            email.body =~ /#{@email.text}/ && email.body =~ /#{@task.name}/ &&
            email.body =~ /#{@attachment.attachment_filename}/ && email.to.include?(@benny.email)
        end
      end

      should 'not email users who are not tracking any items' do
        User.send_tracked_items_mail
        assert_sent_email do |email|
          !email.to.include?(@user)
        end
      end

      should 'not include activities in the email which have already been sent in a previous email' do
        User.send_tracked_items_mail
        comment2 = @lead.comments.create! :subject => 'another comment',
          :text => 'a second comment', :user => @user
        ActionMailer::Base.deliveries.clear
        User.send_tracked_items_mail
        assert_sent_email do |email|
          email.body.match(/#{@lead.name}/) && !email.body.match(/#{@comment.text}/) &&
            !email.body.match(/#{@email.text}/) && !email.body.match(/#{@task.name}/) &&
            !email.body.match(/#{@attachment.attachment_filename}/) &&
            email.to.include?(@benny.email) && email.body.match(/#{comment2.text}/)
        end
      end

      should 'not send an email at all if there are no new activities' do
        User.send_tracked_items_mail
        ActionMailer::Base.deliveries.clear
        User.send_tracked_items_mail
        assert_equal 0, ActionMailer::Base.deliveries.length
      end

      should 'have todays date in the subject' do
        User.send_tracked_items_mail
        assert_sent_email do |email|
          email.subject =~ /#{Date.today.to_s(:long)}/
        end
      end
    end
  end

  context 'Instance' do
    setup do
      @user = User.make_unsaved(:annika)
    end

    should 'create company from company name' do
      @user = User.new User.plan(:annika, :company_name => 'A test company')
      @user.save!
      assert Company.find_by_name('A test company')
      assert_equal 'A test company', @user.company.name
    end

    should 'have dropbox email' do
      @user.save!
      assert_equal "dropbox@#{@user.api_key}.salesflip.com", @user.dropbox_email
    end

    context 'when invited' do
      setup do
        @user.save!
        @invitation = Invitation.make:inviter => @user, :user_type => 'Freelancer',
          :email => 'test@test.com'
      end

      should 'populate details from invitation code' do
        user = User.new :invitation_code => @invitation.code
        assert_equal 'test@test.com', user.email
        assert_equal 'Freelancer', user._type
        assert_equal 'test', user.username
        assert_equal @user.company_id, user.company_id
      end

      should 'be able to override invitation code details' do
        user = User.new :invitation_code => @invitation.code, :username => 'wtf', :email => 'wtf'
        assert_equal 'wtf', user.email
        assert_equal 'wtf', user.username
      end

      should 'update invitation with invited id after creation' do
        user = User.new :invitation_code => @invitation.code, :password => 'password',
          :password_confirmation => 'password'
        user.save!
        assert user.invitation
      end
    end

    should 'update invitation with invited id after create' do
      @user.save!
    end

    context 'deleted_items_count' do
      setup do
        @lead = Lead.make
        @contact = Contact.make
        @account = Account.make
      end

      should 'return a count of all deleted accounts, contacts and leads' do
        assert_equal 0, @user.deleted_items_count
        @lead.destroy
        assert_equal 1, @user.deleted_items_count
        @contact.destroy
        assert_equal 2, @user.deleted_items_count
        @account.destroy
        assert_equal 3, @user.deleted_items_count
      end

      should 'not count permanently deleted items' do
        @lead.destroy
        @lead.destroy_without_paranoid
        assert_equal 0, @user.deleted_items_count
      end
    end

    context 'full_name' do
      should 'return username if present' do
        @user.update_attributes(:username => 'annie')
        @user.save!
        assert_equal @user.full_name, "annie"
      end

      should 'return email if username is not present' do
        @user.save!
        assert_equal @user.full_name, "annika.fleischer1@1000jobboersen.de"
      end
    end

    context 'tracked_items' do
      setup do
        @user.save!
      end

      should 'return all tracked leads' do
        lead = Lead.make(:erich, :tracker_ids => [@user.id])
        assert @user.tracked_items.include?(lead)
      end

      should 'return all tracked contacts' do
        contact = Contact.make(:florian, :tracker_ids => [@user.id])
        assert @user.tracked_items.include?(contact)
      end

      should 'return all tracked accounts' do
        account = Account.make(:careermee, :tracker_ids => [@user.id])
        assert @user.tracked_items.include?(account)
      end
    end

    context 'recent_items' do
      should 'return recently viewed items' do
        @lead = Lead.make
        Activity.log(@user, @lead, 'Viewed')
        assert @user.recent_items.include?(@lead)
      end

      should 'order items by when they where viewed' do
        @lead = Lead.make
        @contact = Contact.make
        @contact2 = Contact.make
        Activity.log(@user, @lead, 'Viewed')
        Activity.log(@user, @contact2, 'Viewed')
        Activity.log(@user, @contact, 'Viewed')
        assert_equal [@contact, @contact2, @lead], @user.recent_items
      end

      should 'return a maximum of 5 items' do
        6.times do
          @lead = Lead.make
          Activity.log(@user, @lead, 'Viewed')
        end
        assert_equal 5, @user.recent_items.length
      end
    end

    should 'have uuid after creation' do
      @user.save!
      assert !@user.api_key.blank?
    end

    should 'be valid' do
      assert @user.valid?
    end

    should 'not be valid with email less than 6 characters long' do
      @user.email = 'a@b.c'
      assert !@user.valid?
      assert @user.errors.on(:email)
    end

    should 'not be valid with email more than 100 characters long' do
      @user.email = 101.times.map { 'a' }.join('')
      assert !@user.valid?
      assert @user.errors.on(:email)
    end

    should 'not be valid with invalid email' do
      @user.email = 'matt'
      assert !@user.valid?
      assert @user.errors.on(:email)
    end

    context 'when new record' do
      should 'not be valid without password' do
        @user.password = nil
        assert !@user.valid?
        assert @user.errors.on(:password)
      end

      should 'not be valid without password confirmation' do
        @user.password_confirmation = nil
        assert !@user.valid?
        assert @user.errors.on(:password)
      end
    end
  end
end
