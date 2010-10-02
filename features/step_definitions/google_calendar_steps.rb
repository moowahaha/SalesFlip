When /^I enter my Google username$/ do
  fill_in 'Google username', :with => google_username
end

When /^I enter my Google password$/ do
  fill_in 'Google password', :with => google_password
end

Then /^there should be a Google calendar entry titled "([^"]*)"$/ do |entry_title|
  service = GCal4Ruby::Service.new
  service.authenticate(google_username, google_password)
  entries = GCal4Ruby::Event.find(service, entry_title)
  entries.should_not be_empty
  entries.first.delete
end

def google_username
  ENV['GOOGLE_USERNAME'] || raise("Set your GOOGLE_USERNAME environment variable")
end

def google_password
  ENV['GOOGLE_PASSWORD'] || raise("Set your GOOGLE_PASSWORD environment variable")
end
