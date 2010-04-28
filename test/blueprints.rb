require 'machinist/mongo_mapper'
require 'sham'
require 'faker'

Sham.first_name { Faker::Name.first_name }
Sham.last_name { Faker::Name.last_name }
Sham.name { Faker::Name.name }
Sham.email { Faker::Internet.email }
Sham.title { Faker::Lorem.sentence }
Sham.sentence { Faker::Lorem.sentence }
Sham.annika_email { |index| "annika.fleischer#{index}@1000jobboersen.de" }

Invitation.blueprint do
  email
  inviter { User.make }
  user_type { 'User' }
end

Configuration.blueprint do
  domain_name 'lean-crm.com'
  company_name 'A company'
end

Company.blueprint do
  name
end

Company.blueprint(:jobboersen) do
  name { '1000JobBoersen' }
end

Freelancer.blueprint do
  company { Company.make }
  email
  password { 'password' }
  password_confirmation { 'password' }
end

User.blueprint do
  company { Company.make }
  email
  password { 'password' }
  password_confirmation { 'password' }
end

User.blueprint(:annika) do
  company { Company.make }
  email { Sham.annika_email }
  password { 'password' }
  password_confirmation { 'password' }
end

User.blueprint(:benny) do
  company { Company.make }
  email { 'benjamin.pochhammer@1000jobboersen.de' }
  password { 'password' }
  password_confirmation { 'password' }
end

Admin.blueprint do
  email
  password { 'password' }
  password_confirmation { 'password' }
end

Admin.blueprint(:matt) do
  email { 'matt.beedle@1000jobboersen.de' }
  password { 'password' }
  password_confirmation { 'password' }
end

Lead.blueprint do
  first_name
  last_name
  user { User.make(:annika) }
end

Lead.blueprint(:with_contact_info) do
  first_name { 'Erich' }
  last_name { 'Feldmeier' }
  user { User.make(:annika) }
  email { "e.feldermeier@yahoo.de" }
  phone { "102.321.2456" }
end

Lead.blueprint(:erich) do
  first_name { 'Erich' }
  last_name { 'Feldmeier' }
  user { User.make(:annika) }
end

Lead.blueprint(:kerstin) do
  first_name { 'Kerstin' }
  last_name { 'Pätzol' }
  user { User.make(:annika) }
  deleted_at { Time.now }
end

Lead.blueprint(:markus) do
  first_name { 'Markus' }
  last_name { 'Sitek' }
  status { 'Rejected' }
  user { User.make(:annika) }
end

Task.blueprint do
  user { User.make(:annika) }
  name { Sham.sentence }
  category { 'Call' }
  due_at { 'overdue' }
end

Task.blueprint(:call_erich) do
  user { User.make(:annika) }
  name { 'Call erich to get offer details' }
  category { 'Call' }
  asset { Lead.make(:erich) }
  due_at { 'due_today' }
end

Account.blueprint do
  name
  user { User.make(:annika) }
end

Account.blueprint(:careermee) do
  name { 'CareerMee' }
  user { User.make(:annika) }
end

Account.blueprint(:with_contact_info) do
  name { 'Contact Inc.' }
  user { User.make(:annika) }
  email { "info@contactinc.com" }
  phone { "102.321.2456" }
end

Account.blueprint(:world_dating) do
  name { 'World Dating' }
  user { User.make(:benny) }
end

Contact.blueprint do
  first_name
  last_name
  user { User.make(:annika) }
  account { Account.make }
end

Contact.blueprint(:with_contact_info) do
  first_name
  last_name
  user { User.make(:annika) }
  account { Account.make }
  email { "contact@info.com" }
  phone { "102.321.2456" }
end

Contact.blueprint(:florian) do
  first_name { 'Florian' }
  last_name { 'Behn' }
  user { User.make(:annika) }
  account { Account.make(:careermee) }
end

Contact.blueprint(:steven) do
  first_name { 'Steven' }
  last_name  { 'Garcia' }
  user       { User.make(:annika) }
  account    { Account.make(:careermee) }
end

Activity.blueprint do
end

Activity.blueprint(:viewed_erich) do
  user    { User.make(:annika) }
  subject { Lead.make(:erich) }
  action  { 'Viewed' }
end

Comment.blueprint do
  user        { User.make }
  commentable { Account.make }
  text        { 'I like it!' }
end

Comment.blueprint(:made_offer_to_erich) do
  user { User.make(:annika) }
  commentable { Lead.make(:erich) }
  text { 'Called erich, made offer' }
end

Attachment.blueprint do
end

Attachment.blueprint(:erich_offer_pdf) do
  subject { Comment.make(:made_offer_to_erich) }
  attachment { File.open("#{Rails.root}/test/upload-files/erich_offer.pdf") }
end

Email.blueprint do
end

Email.blueprint(:erich_offer_email) do
  user { User.make(:annika) }
  commentable { Lead.make(:erich) }
  text { 'Here is the offer body' }
  subject { 'A great offer for you' }
  received_at { 1.day.ago }
  from { 'annika.fleischer@1000jobboersen.de' }
end

Search.blueprint do
  user { User.make(:annika) }
  terms { Sham.name }
end
