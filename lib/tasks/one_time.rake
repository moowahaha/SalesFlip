require 'csv'

namespace(:one_time) do
  desc "Import Mandy's leads"
  task :import_mandys_leads => :environment do
    CSV.open('doc/mandys_leads.csv', 'r', '|') do |row|
      user = User.find_by_email('mandy.cash@1000jobboersen.de')
      lead = user.leads.build :assignee => user, :do_not_log => true, :do_not_notify => true
      %w(salutation first_name last_name company phone email).each_with_index do |key, index|
        lead.send("#{key}=", row[index] ? row[index].strip : nil)
      end
      lead.save!
    end
  end

  desc 'Add identifiers to all accounts, leads and contacts'
  task :add_identifiers => :environment do
    Account.all(:identifier => nil).each do |account|
      account.update_attributes :do_not_geocode => true, :identifier => Identifier.next_account,
        :do_not_log => true
    end
    Contact.all(:identifier => nil).each do |contact|
      contact.update_attributes :do_not_geocode => true, :identifier => Identifier.next_contact,
        :do_not_log => true
    end
    Lead.all(:identifier => nil).each do |lead|
      lead.update_attributes :do_not_geocode => true, :identifier => Identifier.next_lead,
        :do_not_notify => true, :do_not_log => true
    end
  end

  desc 'Update old style lead-contact relationship, to new style contact has_many leads'
  task :switch_contact_leads_to_has_many => :environment do
    Contact.all(:lead_id => { '$ne' => nil }).each do |contact|
      lead = Lead.first(:id => contact.lead_id)
      lead.update_attributes :contact_id => contact.id, :do_not_log => true
    end
  end

  desc 'Transfer abstract users'
  task :transfer_abstract_users => :environment do
    AbstractUser.all.each do |abstract_user|
      user = User.new(abstract_user.attributes)
      user.save(false)
      user.confirm!
    end
  end

  desc 'Add company scoping (1000JobBoersen.de)'
  task :add_company => :environment do
    c = Company.find_or_create_by_name('1000JobBoersen.de')
    User.all.each do |user|
      user.update_attributes :company_id => c.id
    end
  end

  desc 'Import helios dataset'
  task :helios_import => :environment do
    headings = ["title", "first_name", "last_name", "salutation", "job_title", "company",
      "department", "address", "postal_code", "city", "country", "phone", "email"]
    CSV.open('doc/helios.csv', 'r', '|') do |row|
      u = User.find_by_email('mattbeedle@googlemail.com')
      l = u.leads.build :source => 'Helios'
      headings.each_with_index do |heading,index|
        l.send("#{heading}=", row[index] ? row[index].strip : nil)
      end
      l.save!
    end
  end
end
