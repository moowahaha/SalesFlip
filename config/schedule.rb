set :environment, 'production'

every 1.day, :at => '7am' do
  command "/var/www/salesflip/current/script/runner Task.daily_email"
  command "/var/www/salesflip/current/script/runner User.send_tracked_items_mail"
end
