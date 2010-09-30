class PagesController < ApplicationController

  before_filter :find_activities, :only => [ :index ]
  before_filter :find_tasks,      :only => [ :index ]

protected
  def find_activities
    @activities ||= Activity.action_is_not('Viewed').order_by(['created_at', 'desc']).
      limit(20).visible_to(current_user)
  end

  def find_tasks
    @overdue ||= Task.for(current_user).incomplete.overdue.desc(:due_at)
    @due_today ||= Task.for(current_user).incomplete.due_today.desc(:due_at)
  end
end
