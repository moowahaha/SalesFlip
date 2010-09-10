class PagesController < ApplicationController

  before_filter :find_activities, :only => [ :index ]
  before_filter :find_tasks,      :only => [ :index ]

protected
  def find_activities
    @activities ||= Activity.action_is_not('Viewed').order_by(['created_at', 'desc']).
      limit(20).visible_to(current_user)
  end

  def find_tasks
    @tasks ||= Task.for(current_user).incomplete.desc(:due_at).limit(10)
  end
end
