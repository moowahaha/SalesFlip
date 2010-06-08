Given /^I have an invitation$/ do
  user = User.make(:annika)
  user.confirm!
  store_model('user', 'annika', user)
  invitation = Invitation.make :email => 'werner@1000jobboersen.de', :inviter => user
  store_model('invitation', 'invitation', invitation)
end

Given /^I have a Freelancer invitation$/ do
  user = User.make(:annika)
  user.confirm!
  store_model('user', 'annika', user)
  invitation = Invitation.make :email => 'werner@1000jobboersen.de', :inviter => user, :user_type => 'Freelancer'
  store_model('invitation', 'invitation', invitation)
end

Given /^I am logged in as #{capture_model}$/ do |m|
  model = model!(m)
  visit new_user_session_path
  fill_in 'user_email', :with => model.email
  fill_in 'user_password', :with => 'password'
  click_button 'user_submit'
end

Given /^#{capture_model} is confirmed$/ do |m|
  model!(m).confirm!
end
