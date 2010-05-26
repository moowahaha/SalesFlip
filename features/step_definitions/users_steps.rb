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
