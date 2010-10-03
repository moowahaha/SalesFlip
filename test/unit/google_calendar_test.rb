require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class GoogleCalendarTest < ActiveSupport::TestCase
  setup do
    @task = Task.make

    @fake_service = mock('google service')
    GCal4Ruby::Service.stubs(:new).returns(@fake_service)
    @fake_service.stubs(:authenticate)

    @fake_calendars = mock('list of calendars')
    @fake_service.stubs(:calendars).returns(@fake_calendars)

    @fake_calendar = mock('calendar')
    @fake_calendars.stubs(:first).returns(@fake_calendar)

  end

  should "login to google calendar" do
    @fake_service.expects(:authenticate).with('aaa', 'bbb')

    @task.google_username = 'aaa'
    @task.google_password = 'bbb'

    GoogleCalendar.new(@task)
  end

  should "pick the user's first calendar" do
    @fake_calendars.expects(:first)
    GoogleCalendar.new(@task)
  end

  context "instance" do
    setup do
      @google_calendar = GoogleCalendar.new(@task)
    end

    should 'create a new event if one does not already exist' do
      GCal4Ruby::Event.stubs(:find).returns(nil)

      @task.due_at = Time.zone.now + 1.hour
      @task.name = 'harold'

      fake_event = mock('event')

      GCal4Ruby::Event.expects(:new).with(@fake_service).returns(fake_event)

      fake_event.expects(:calendar=).with(@fake_calendar)
      fake_event.expects(:start_time=).with(@task.due_at)
      fake_event.expects(:end_time=).with(@task.due_at + 30.minutes)
      fake_event.expects(:title=).with('harold')
      fake_event.expects(:id).returns('hello')
      fake_event.expects(:save)

      assert_equal @google_calendar.record_task, 'hello'
    end

    should 'update an existing event' do
      @task.due_at = Time.zone.now + 1.hour
      @task.name = 'harold'
      @task.google_event_id = 'some id'

      @task.save
      
      @task.due_at = Time.zone.now + 2.hours
      @task.name = 'timothy'

      fake_event = mock('event')

      GCal4Ruby::Event.expects(:find).with(@fake_service, {:id => 'some id'}).returns(fake_event)

      fake_event.expects(:calendar=).with(@fake_calendar)
      fake_event.expects(:start_time=).with(@task.due_at)
      fake_event.expects(:end_time=).with(@task.due_at + 30.minutes)
      fake_event.expects(:title=).with('timothy')
      fake_event.expects(:id).returns('123')
      fake_event.expects(:save)

      assert_equal @google_calendar.record_task, '123'
    end

    should 'delete an event' do
      fake_event = mock('event')
      GCal4Ruby::Event.expects(:find).with(@fake_service, {:id => 'monkey business'}).returns(fake_event)
      fake_event.expects('delete')
      @task.google_event_id = 'monkey business'

      @google_calendar.remove_task
    end
  end
end
