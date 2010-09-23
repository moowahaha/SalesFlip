Given /^careermee is shared with annika$/ do
  c = Account.where(:name => /CareerMee/i).first
  a = User.where(:email => 'annika.fleischer@1000jobboersen.de').first
  c.update_attributes :permission => 'Shared', :permitted_user_ids => [a.id]
end

Given /^I follow the edit link for the account$/ do
  click "edit_account_#{Account.last.id}"
end

Given /^I click the delete button for the task$/ do
  click "delete_task_#{Task.first.id}"
end

Then /^#{capture_model} should have sub account: #{capture_model}$/ do |parent, sub|
  parent = model!(parent)
  sub = model!(sub)
  assert parent.children.include?(sub)
end
