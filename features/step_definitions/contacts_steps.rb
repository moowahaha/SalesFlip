Given /^florian is shared with annika$/ do
  u = User.first(:conditions => { :email => 'annika.fleischer@1000jobboersen.de' })
  c = Contact.first(:conditions => { :first_name => 'Florian' })
  c.update_attributes :permission => 'Shared', :permitted_user_ids => [u.id]
end

Given /^I follow the edit link for the contact$/ do
  click "edit_contact_#{Contact.last.id}"
end

Then /^#{capture_model} should have a contact with first_name: "(.+)"$/ do |target, first_name|
  assert model!(target).contacts.find(:first, :conditions => { :first_name => first_name })
end
