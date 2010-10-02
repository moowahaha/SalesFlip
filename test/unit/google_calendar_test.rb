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

    should 'create a new event' do
      @task.due_at = Time.zone.now + 1.hour

      @task.name = 'harold'

      fake_event = mock('event')

      GCal4Ruby::Event.expects(:new).with(
              @fake_service,
              {
                      :calendar => @fake_calendar,
                      :title => 'harold',
                      :start_time => @task.due_at,
                      :end_time => @task.due_at + 30.minutes

              }
      ).returns(fake_event)

      fake_event.expects(:save)

      @google_calendar.record_task
    end
  end
end
