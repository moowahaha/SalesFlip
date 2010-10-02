class GoogleCalendar
  def initialize task
    @task = task
    login
    select_calendar
  end

  def record_task
    GCal4Ruby::Event.new(
            @google_service,
            {
                    :calendar => @calendar,
                    :title => @task.name,
                    :start_time => @task.due_at,
                    :end_time => @task.due_at + 30.minutes
            }
    ).save
  end

  def remove_task
    GCal4Ruby::Event.find(@google_service, @task.name).first.delete
  end

  private

  def select_calendar
    @calendar = @google_service.calendars.first
  end

  def login
    @google_service = GCal4Ruby::Service.new
    @google_service.authenticate(@task.google_username, @task.google_password)
  end
end