Then /^I should see "([^"]*)" in the source$/ do |val|
  assert page.body.match(/#{val}/)
end

Given /^I should not see "([^"]*)" in the source$/ do |val|
  assert !page.body.match(/#{val}/)
end
