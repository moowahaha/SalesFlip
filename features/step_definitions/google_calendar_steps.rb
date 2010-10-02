When /^I enter my Google username$/ do
  fill_in 'Google username', :with => google_username
end

When /^I enter my Google password$/ do
  fill_in 'Google password', :with => google_password
end

Then /^there should be a Google calendar entry titled "([^"]*)"$/ do |entry_title|
  entries = google_calendar_entries(entry_title)
  entries.should_not be_empty
  entries.first.delete
end

Then /^there should not be a Google calendar entry titled "([^"]*)"$/ do |entry_title|
  google_calendar_entries(entry_title).should be_empty
end

def google_calendar_entries(title)
  service = GCal4Ruby::Service.new
  service.authenticate(google_username, google_password)
  entries = GCal4Ruby::Event.find(service, title)
  return entries
end

def google_username
  ENV['GOOGLE_USERNAME'] || raise("Set your GOOGLE_USERNAME environment variable")
end

def google_password
  ENV['GOOGLE_PASSWORD'] || raise("Set your GOOGLE_PASSWORD environment variable")
end
