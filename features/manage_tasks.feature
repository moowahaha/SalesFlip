Feature: Manage tasks
  In order to remember to do jobs
  A User
  wants to add, update, delete and be reminded of tasks

  Scenario: Tasks on the dashboard
    Given I am registered and logged in as annika
    And Benny exists
    And a task exists with user: Annika, name: "Task for Annika"
    And a task exists with user: Benny, name: "Task for Benny"
    And a task exists with user: Annika, name: "Completed Task for Annika", completed_at: "10 Oct 2009"
    And a task exists with user: Annika, name: "Future Task for Annika", due_at: "10 Oct 3000"
    When I am on the dashboard page
    Then I should see "Task for Annika" within "#tasks"
    And I should not see "Task for Benny" within "#tasks"
    And I should not see "Completed Task for Annika" within "#tasks"
    And I should not see "Future Task for Annika" within "#tasks"
    And I should see "As soon as possible" within "#tasks"
    And I should not see "You have no outstanding tasks" within "#tasks"

  Scenario: Tasks on the dashboard when there are no tasks
    Given I am registered and logged in as annika
    When I am on the dashboard page
    Then I should not see "As soon as possible" within "#tasks"
    And I should not see "Today" within "#tasks"
    And I should see "You have no outstanding tasks" within "#tasks"

  Scenario: Creating a new task
    Given I am registered and logged in as annika
    And I am on the tasks page
    And I follow "new"
    And I follow "preset_date"
    And I fill in "task_name" with "a test task"
    And I select "Call" from "task_category"
    And I select "Today" from "task_due_at"
    When I press "task_submit"
    Then I should be on the tasks page
    And I should see "a test task"

  Scenario: Viewing my tasks
    Given I am registered and logged in as annika
    And a task exists with user: annika, name: "Task for Annika"
    And Annika has invited Benny
    And a task exists with user: benny, name: "Task for Benny"
    And I am on the dashboard page
    When I follow "Tasks"
    Then I should see "Task for Annika"
    And I should not see "Task for Benny"

  Scenario: Re-assiging a task
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a task: "call_erich" exists with user: annika
    And all emails have been delivered
    And I follow "Tasks"
    And I follow the edit link for the task
    And I follow "preset_date"
    When I select "benjamin.pochhammer@1000jobboersen.de" from "task_assignee_id"
    And I select "Today" from "task_due_at"
    And I press "update_task"
    Then I should be on the tasks page
    And I should see "Task has been re-assigned"
    And a task re-assignment email should have been sent to "benjamin.pochhammer@1000jobboersen.de"

  Scenario: Filtering pending tasks
    Given I am registered and logged in as annika
    And a task: "call_erich" exists with user: annika
    And a task exists with user: annika, name: "test task", completed_at: "12th March 2000"
    And I am on the tasks page
    When I follow "pending"
    Then I should see "erich"
    And I should not see "test task"

  Scenario: Filtering assigned tasks
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a task: "call_erich" exists with user: annika
    And a task exists with user: annika, assignee: annika, name: "annika's task"
    And a task exists with user: benny, assignee: benny, name: "benny's task"
    And a task exists with user: benny, assignee: annika, name: "task for annika"
    And a task exists with user: annika, assignee: benny, name: "a task for benny"
    When I am on the tasks page
    And I follow "assigned"
    Then I should not see "Erich"
    And I should not see "annika's task"
    And I should not see "benny's task"
    And I should not see "task for annika"
    And I should see "a task for benny"

  Scenario: Filtering overdue pending tasks
    Given I am registered and logged in as annika
    And a task: "call_erich" exists with user: annika, due_at: "overdue"
    And a task exists with user: annika, name: "another task", due_at: "due_next_week"
    When I am on the tasks page
    And I follow "pending"
    And I check "overdue"
    And I press "filter"
    Then I should see "erich"
    And I should not see "another task"

  Scenario: Filtering pending tasks due today
    Given I am registered and logged in as annika
    And a task "call_erich" exists with user: annika, due_at: "due_today"
    And a task exists with user: annika, name: "another task", due_at: "due_next_week"
    When I am on the tasks page
    And I follow "pending"
    And I check "due_today"
    And I press "filter"
    Then I should see "erich"
    And I should not see "another task"

  Scenario: Filtering pending tasks due tomorrow
    Given I am registered and logged in as annika
    And a task "call_erich" exists with user: annika, due_at: "due_tomorrow"
    And a task exists with user: annika, name: "another task", due_at: "due_next_week"
    When I am on the tasks page
    And I follow "pending"
    And I check "due_tomorrow"
    And I press "filter"
    Then I should see "erich"
    And I should not see "another task"

  Scenario: Filtering pending tasks due next week
    Given I am registered and logged in as annika
    And a task: "call_erich" exists with user: annika, due_at: "overdue"
    And a task exists with user: annika, name: "another task", due_at: "due_next_week"
    When I am on the tasks page
    And I follow "pending"
    And I check "due_next_week"
    And I press "filter"
    Then I should see "another task"
    And I should not see "erich"

  Scenario: Filtering pending tasks due later
    Given I am registered and logged in as annika
    And a task: "call_erich" exists with user: annika, due_at: "overdue"
    And a task exists with user: annika, name: "another task", due_at: "due_later"
    When I am on the tasks page
    And I follow "pending"
    And I check "due_later"
    And I press "filter"
    Then I should see "another task"
    And I should not see "erich"

  Scenario: Filtering several pending tasks
    Given I am registered and logged in as annika
    And a task: "call_erich" exists with user: annika, due_at: "overdue"
    And a task exists with user: annika, name: "another task", due_at: "due_later"
    And a task exists with user: annika, name: "third task", due_at: "due_next_week"
    When I am on the tasks page
    And I follow "pending"
    And I check "overdue"
    And I check "due_later"
    And I press "filter"
    Then I should see "another task"
    And I should see "erich"
    And I should not see "third task"

  Scenario: Creating a Google calendar entry
    Given I am registered and logged in as annika
    And I am on the tasks page
    When I follow "new"
    And I follow "preset_date"
    And I fill in "Subject" with "a test task"
    And I select "Call" from "Category"
    And I select "Tomorrow" from "task_due_at"
    And I enter my Google username
    And I enter my Google password
    And I press "Create Task"
    Then there should be a Google calendar entry titled "a test task"

  Scenario: Removing a Google calendar entry
    Given I am registered and logged in as annika
    And I am on the tasks page
    When I follow "new"
    And I follow "preset_date"
    And I fill in "Subject" with "a test task"
    And I select "Call" from "Category"
    And I select "Tomorrow" from "task_due_at"
    And I enter my Google username
    And I enter my Google password
    And I press "Create Task"
    And I am on the tasks page
    And I delete my task
    Then there should not be a Google calendar entry titled "a test task"


# TODO get this working with mongoDB, currently tries to use ActiveRecord for some weird reason
#@javascript
#Scenario: Completing a task
#  Given I am registered and logged in as annika
#  And a task: "call_erich" exists with user: annika, due_at: "overdue"
#  When I am on the tasks page
#  And I check task: "call_erich"
#  Then I should not see "Edit"
#  And I should not see "delete_task"
#  And a task exists with user: annika, name: "call_erich", completed_at: !nil
