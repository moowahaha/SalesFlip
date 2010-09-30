namespace :salesflip do
  desc 'Setup new project'
  task :setup => :environment do
    c = Company.create! :name => 'Test Company'
    user = c.users.create! :email => 'test@test.com', :password => 'password',
      :password_confirmation => 'password'
    user.confirm!
  end
end
