require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class TaskTest < ActiveSupport::TestCase
  context "Class" do
    should_have_constant :categories
    should_require_key :user, :due_at, :name, :category

    should 'allow multiparameter attributes for due_at' do
      time = Time.zone.now
      obj = Task.new "due_at(1i)" => time.year.to_s,
                     "due_at(2i)" => time.month.to_s,
                     "due_at(3i)" => time.day.to_s,
                     "due_at(4i)" => time.hour.to_s,
                     "due_at(5i)" => time.min.to_s,
                     "due_at(6i)" => time.sec.to_s
      obj.valid?
      assert_equal time.to_i, obj.due_at.to_i
    end

    context 'grouped_by_scope' do
      setup do
        @task = Task.make :due_at => 'due_next_week'
        @task2 = Task.make :due_at => 'overdue'
      end

      should 'return tasks grouped by the supplied scopes' do
        result = Task.grouped_by_scope(['due_next_week', 'overdue'])
        assert result.is_a?(Hash)
        assert_equal [@task], result[:due_next_week].to_a
        assert_equal [@task2], result[:overdue].to_a
      end

      should 'scope tasks to the supplied scope' do
        @task3 = Task.make :due_at => 'due_next_week'
        @task3.update_attributes :completed_by_id => @task3.user_id
        result = Task.grouped_by_scope(['due_next_week'], :target => Task.incomplete)
        assert result[:due_next_week].include?(@task)
        assert !result[:due_next_week].include?(@task3)
      end

      should 'not do anything for undefined scopes' do
        assert Task.grouped_by_scope(['whtafdsf']) == {}
      end
    end

    context 'daily_email' do
      setup do
        @call_erich = Task.make(:call_erich, :due_at => 'due_today')
        @call_markus = Task.make(:call_markus, :due_at => 'due_today', :user => User.make(:benny))
        ActionMailer::Base.deliveries.clear
      end

      should 'have todays date in the subject' do
        Task.daily_email
        assert_sent_email do |email|
          email.subject =~ /#{Date.today.to_s(:long)}/
        end
      end

      should 'not send an email if there are no tasks due' do
        @call_erich.update_attributes :due_at => 'due_next_week'
        @call_markus.update_attributes :due_at => 'due_next_week'
        ActionMailer::Base.deliveries.clear
        Task.daily_email
        assert_equal 0, ActionMailer::Base.deliveries.length
      end

      should 'send an email to all users who have tasks due for the day' do
        Task.daily_email
        assert_sent_email do |email|
          email.to.include?(@call_erich.user.email) && email.body.match(/#{@call_erich.name}/)
        end
        assert_sent_email do |email|
          email.to.include?(@call_markus.user.email) && email.body.match(/#{@call_markus.name}/)
        end
      end

      should 'send a summary email to each user, with all tasks in one email' do
        @call_markus.update_attributes :user_id => @call_erich.user_id
        Task.daily_email
        assert_sent_email do |email|
          email.to.include?(@call_markus.user.email) && email.body.match(/#{@call_markus.name}/) &&
                  email.body.match(/#{@call_erich.name}/)
        end
      end

      should 'only send tasks for the current day or overdue' do
        @call_erich.update_attributes :due_at => 'due_next_week'
        Task.daily_email
        assert_sent_email do |email|
          email.to.include?(@call_markus.user.email) && email.body.match(/#{@call_markus.name}/) &&
                  !email.body.match(/#{@call_erich.name}/)
        end
        @call_erich.update_attributes :due_at => 'overdue'
        Task.daily_email
        assert_sent_email do |email|
          email.to.include?(@call_erich.user.email) && email.body.match(/#{@call_erich.name}/)
        end
      end
    end
  end

  context 'Named Scopes' do
    setup do
      @task = Task.make(:call_erich)
    end

    context 'assigned_by' do
      setup do
        @task2 = Task.make(:user_id => @task.user.id)
        @task2.update_attributes :assignee => User.make
      end

      should 'return all tasks assigned to anyone except the task creator' do
        assert_equal [@task2], Task.assigned_by(@task.user).to_a
      end
    end

    context 'overdue' do
      setup do
        @task.update_attributes :due_at => 'due_next_week'
        @task2 = Task.make :due_at => 'overdue'
      end

      should 'return tasks which are due yesterday or earlier' do
        assert_equal [@task2], Task.overdue.to_a
      end
    end

    context 'due_today' do
      setup do
        @task.update_attributes :due_at => 'overdue'
        @task2 = Task.make :due_at => 'due_today'
      end

      should 'return tasks which are due today' do
        assert_equal [@task2], Task.due_today.to_a
      end
    end

    context 'due_tomorrow' do
      setup do
        @task.update_attributes :due_at => 'overdue'
        @task2 = Task.make :due_at => 'due_tomorrow'
      end

      should 'return tasks which are due tomorrow' do
        assert_equal [@task2], Task.due_tomorrow.to_a
      end
    end

    context 'due_next_week' do
      setup do
        @task.update_attributes :due_at => 'overdue'
        @task2 = Task.make :due_at => 'due_next_week'
      end

      should 'return tasks which are due next week' do
        assert_equal [@task2], Task.due_next_week.to_a
      end
    end

    context 'due_later' do
      setup do
        @task.update_attributes :due_at => 'overdue'
        @task2 = Task.make :due_at => 6.months.from_now
      end

      should 'return tasks which are due after next week' do
        assert_equal [@task2], Task.due_later.to_a
      end
    end

    context 'completed_today' do
      setup do
        @task2 = Task.make
        @task2.update_attributes :completed_by_id => @task2.user_id
        @task2.update_attributes :completed_at => Time.zone.now
      end

      should 'return tasks which were completed today' do
        assert_equal [@task2], Task.completed_today.to_a
      end
    end

    context 'completed_yesterday' do
      setup do
        @task2 = Task.make
        @task2.update_attributes :completed_by_id => @task2.user_id
        @task2.update_attributes :completed_at => Time.zone.now.yesterday.utc
      end

      should 'return tasks which were completed yesterday' do
        assert_equal [@task2], Task.completed_yesterday.to_a
      end
    end

    context 'completed_last_week' do
      setup do
        @task2 = Task.make
        @task2.update_attributes :completed_by_id => @task2.user_id
        @task2.update_attributes :completed_at => Time.zone.now.beginning_of_week.utc - 7.days
      end

      should 'return tasks which where completed last week' do
        assert_equal [@task2], Task.completed_last_week.to_a
      end
    end

    context 'completed_last_month' do
      setup do
        @task2 = Task.make
        @task2.update_attributes :completed_by_id => @task2.user_id
        @task2.update_attributes :completed_at => (Time.zone.now.beginning_of_month.utc + 1.day) - 1.month
      end

      should 'return tasks which where completed last month' do
        assert_equal [@task2], Task.completed_last_month.to_a
      end
    end

    context 'completed' do
      setup do
        @task = Task.make(:call_erich)
        @task.update_attributes :completed_by_id => @task.user.id
        @incomplete = Task.make
      end

      should 'return all completed tasks' do
        assert_equal [@task], Task.completed.to_a
      end
    end

    context 'assigned' do
      setup do
        @benny = User.make(:benny)
        @assigned = Task.make(:call_erich)
        @assigned.update_attributes :assignee_id => @benny.id
        @unassigned = Task.make
      end

      should 'return all assigned tasks' do
        assert_equal [@assigned], Task.assigned.to_a
      end
    end

    context 'for' do
      should 'return all tasks created by the supplied user' do
        assert_equal [@task], Task.for(@task.user).to_a
      end

      should 'return all tasks assigned to the current user' do
        @benny = User.make(:benny)
        @task.update_attributes :assignee_id => @benny.id
        assert_equal [@task], Task.for(@benny).to_a
      end

      should 'not return tasks which were created by the supplied user, but are assigned to someone else' do
        @task.update_attributes :assignee => User.make(:benny)
        assert_equal [], Task.for(@task.user).to_a
      end

      should 'not return tasks not created by or assigned to the supplied user' do
        @benny = User.make(:benny)
        assert_equal [], Task.for(@benny).to_a
      end
    end

    context 'incomplete' do
      should 'return tasks which have not been completed' do
        assert_equal [@task], Task.incomplete.to_a
        @task.completed_by_id = @task.user_id
        @task.save
        assert_equal [], Task.incomplete.to_a
      end
    end

    context 'due_today' do
      setup do
        @task.update_attributes :due_at => 'due_today'
        @call_markus = Task.make(:call_markus, :due_at => 'overdue')
      end

      should 'return tasks which are due before 00:00:00 tomorrow' do
        assert_equal [@task], Task.due_today.to_a
      end
    end
  end

  context "Instance" do
    setup do
      @task = Task.make_unsaved
    end

    context 'when created against an unassigned lead' do
      setup do
        @lead = Lead.make(:erich, :assignee_id => nil)
        @user = User.make(:benny)
      end

      should 'assign the lead to the user who created the task' do
        @lead.tasks.create! :user => @user, :name => 'test', :due_at => Time.zone.now,
                            :category => Task.categories.first
        assert_equal @lead.reload.assignee, @user
      end
    end

    should 'be valid with all required attributes' do
      assert @task.valid?
    end

    context 'activity logging' do
      setup do
        @task.save!
      end

      should 'log activity when created' do
        assert @task.activities.any? { |a| a.action == 'Created' }
      end

      should 'log activity when update' do
        @task.update_attributes :name => 'test update'
        assert @task.activities.any? { |a| a.action == 'Updated' }
      end

      should 'not log update activity when created' do
        assert_equal 1, @task.activities.count
      end

      should 'log activity when re-assigned' do
        @task.update_attributes :assignee_id => User.make(:benny).id
        assert @task.activities.any? { |a| a.action == 'Re-assigned' }
      end

      should 'not log update activity when re-assigned' do
        @task.update_attributes :assignee_id => User.make(:benny).id
        assert !@task.activities.any? { |a| a.action == 'Updated' }
      end

      should 'log activity when completed' do
        @task.completed_by_id = @task.user.id
        @task.save!
        assert @task.activities.any? { |a| a.action == 'Completed' }
      end
    end


    should 'send a notification email to the assignee if the assignee is changed' do
      @task.save!
      @benny = User.make(:benny)
      ActionMailer::Base.deliveries.clear
      @task.update_attributes :assignee_id => @benny.id
      assert_sent_email do |email|
        email.to.include?(@benny.email) && email.body.match(/\/tasks\//) &&
                email.subject.match(/You have been assigned a new task/)
      end
    end

    should 'not send a notification email if the assignee was not changed' do
      @task.save!
      ActionMailer::Base.deliveries.clear
      @task.update_attributes :assignee_id => @task.assignee_id
      assert_equal 0, ActionMailer::Base.deliveries.length
    end

    should 'not send a notification email when the task is created if the assignee is blank' do
      @task = Task.make_unsaved(:call_erich, :user => User.make)
      ActionMailer::Base.deliveries.clear
      @task.save!
      assert_equal 0, ActionMailer::Base.deliveries.length
    end

    context 'completed?' do
      should 'be true when task has been completed' do
        @task.completed_by_id = @task.user_id
        @task.save!
        assert @task.completed?
      end

      should 'be false when the task has not been completed' do
        assert !@task.completed?
      end
    end

    context 'completed_by_id=' do
      setup do
        @task.save!
      end

      should 'set the task completed at time' do
        assert @task.completed_at.nil?
        @task.completed_by_id= @task.user_id
        assert !@task.completed_at.nil?
      end

      should 'set the task completed by' do
        assert @task.completed_by_id.nil?
        @task.completed_by_id = @task.user_id
        assert_equal @task.user_id, @task.completed_by_id
      end
    end

    context 'due_in_words' do
      should 'return overdue when due_at is at the end of a day and in the past' do
        @task.due_at = Time.zone.now.yesterday.end_of_day
        assert_equal 'overdue', @task.due_at_in_words
      end

      should 'return "due_today" when due_at is at the end of today' do
        @task.due_at = Time.zone.now.end_of_day
        assert_equal 'due_today', @task.due_at_in_words
      end

      should 'return "due_tomorrow" when due_at is at the end of tomorrow' do
        @task.due_at = Time.zone.now.tomorrow.end_of_day
        assert_equal 'due_tomorrow', @task.due_at_in_words
      end

      #should 'return "due_this_week" when due_at is at the end of a day and some time this week, but further away than tomorrow' do
      #  @task.due_at = Time.zone.now.end_of_week - 1.second
      #  assert_equal 'due_this_week', @task.due_at_in_words
      #end

      should 'return "due_next_week" when due_at is at the end of a day sometime during the following week' do
        @task.due_at = Time.zone.now.next_week.end_of_week
        assert_equal 'due_next_week', @task.due_at_in_words
      end

      should 'return "due_later" when due_at is at the end of a day and further away than one week' do
        @task.due_at = Time.zone.now.next_week.end_of_week + 1.day
        assert_equal 'due_later', @task.due_at_in_words
      end

      should 'return specific time if due_at does not match any of the above cases' do
        time = Time.zone.now
        @task.due_at = time
        assert_equal time.to_s(:short), @task.due_at_in_words
      end
    end

    context 'due_at=' do
      should 'set due_at to midnight yesterday when "overdue" is specified' do
        @task.due_at = 'overdue'
        assert Time.zone.now.yesterday.end_of_day.to_i == @task.due_at.to_i
      end

      should 'set due_at to midnight today when "due_today" is specified' do
        @task.due_at = 'due_today'
        assert Time.zone.now.end_of_day.to_i == @task.due_at.to_i
      end

      should 'set due_at to midnight tomorrow when "due_tomorrow" is specified' do
        @task.due_at = 'due_tomorrow'
        assert Time.zone.now.tomorrow.end_of_day.to_i == @task.due_at.to_i
      end

      should 'set due_at to end of week if "due_this_week" is specified' do
        @task.due_at = 'due_this_week'
        assert Time.zone.now.end_of_week.to_i == @task.due_at.to_i
      end

      should 'set due_at to end of next week if "due_next_week" is specified' do
        @task.due_at = 'due_next_week'
        assert Time.zone.now.next_week.end_of_week.to_i == @task.due_at.to_i
      end

      should 'set due_at to 100 years from midnight if "due_later" is specified' do
        @task.due_at = 'due_later'
        assert((Time.zone.now.end_of_day + 5.years).to_i == @task.due_at.to_i)
      end

      should 'attempt to use chronic' do
        time = Chronic.parse('next tuesday')
        @task.due_at = 'next tuesday'
        assert time.to_i, @task.due_at.to_i
      end

      should 'set due_at to specified time, if an actual time is specified' do
        time = 5.minutes.from_now
        @task.due_at = time
        assert_equal time.to_i, @task.due_at.to_i
      end
    end

    context "google calendar" do
      setup do
        @task.google_username = 'aaa'
        @task.google_password = 'bbb'
      end

      should "create a google calendar entry for new tasks" do
        fake_calendar = mock('google calendar')
        GoogleCalendar.expects(:new).with(@task).returns(fake_calendar)
        fake_calendar.expects(:record_task)

        @task.save
      end

      should "not instantiate a google calendar twice for one task instance" do
        fake_calendar = mock('calendar')
        GoogleCalendar.stubs(:new).returns(fake_calendar)
        fake_calendar.stubs(:record_task)

        @task.save

        GoogleCalendar.expects(:new).never

        @task.save
      end

      should "not create a google calendar entry when we don't supply a username or password" do
        @task.google_username = ''
        @task.google_password = ''

        GoogleCalendar.expects(:new).never
        @task.save
      end

      should "remove a google calendar entry when we destroy a task" do
        fake_calendar = mock('calendar')        
        GoogleCalendar.stubs(:new).returns(fake_calendar)
        fake_calendar.stubs(:record_task)

        @task.save

        fake_calendar.expects(:remove_task)

        @task.destroy
      end
    end
  end
end
