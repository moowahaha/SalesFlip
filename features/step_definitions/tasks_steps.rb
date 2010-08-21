Given /^the following tasks:$/ do |tasks|
  Tasks.create!(tasks.hashes)
end

When /^I follow the edit link for the task$/ do
  click "edit_task_#{Task.last.id}"
end

When /^I delete the (\d+)(?:st|nd|rd|th) tasks$/ do |pos|
  visit tasks_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following tasks:$/ do |expected_tasks_table|
  expected_tasks_table.diff!(tableish('table tr', 'td,th'))
end

Then /^the task "(.+)" should have been completed$/ do |name|
  assert Task.where(:name => name).first.completed?
end

Then /^a task re\-assignment email should have been sent to "([^\"]*)"$/ do |email_address|
  truth = ActionMailer::Base.deliveries.any? do |d|
    d.to.include?(email_address) && d.body.match(/\/tasks\//)
  end
  assert truth
end
