class GoogleCalendar
  def initialize task
    @task = task
    login
    select_calendar
  end

  def record_task
    event = fetch_event

    event.calendar = @calendar
    event.title = @task.name
    event.start_time = @task.due_at
    event.end_time = @task.due_at + 30.minutes
    event.save
    event.id
  end

  def remove_task
    GCal4Ruby::Event.find(@google_service, {:id => @task.google_event_id}).delete unless @task.google_event_id.blank?
  end

  private

  def fetch_event
    existing_event || GCal4Ruby::Event.new(@google_service)
  end

  def existing_event
    GCal4Ruby::Event.find(@google_service, {:id => @task.google_event_id}) unless @task.google_event_id.blank?
  end

  def select_calendar
    @calendar = @google_service.calendars.first
  end

  def login
    @google_service = GCal4Ruby::Service.new
    @google_service.authenticate(@task.google_username, @task.google_password)
  end
end