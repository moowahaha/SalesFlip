module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    when /the new comments page/
      new_comments_path

    when /the new users page/
      new_users_path

    when /the new activities page/
      new_activities_path


    when /the login page/
      new_user_session_path

    when /the dashboard page/
      root_path
    when /the registration page/
      new_user_path

    when /the new lead page/
      new_lead_path
    when /the leads page/
      leads_path
    when /the lead page/
      lead_path(@lead || Lead.last(:order => 'created_at'))
    when /the edit lead page/
      edit_lead_path(@lead || Lead.last(:order => 'created_at'))

    when /the new account page/
      new_account_path
    when /the accounts page/
      accounts_path
    when /the account page/
      account_path(@account || Account.last(:order => 'created_at'))

    when /the new contact page/
      new_contact_path
    when /the contacts page/
      contacts_path
    when /the contact page/
      contact_path(@contact || Contact.last(:order => 'created_at'))

    when /the admin login page/
      new_admin_session_path
    when /the admin dashboard page/
      admin_root_path

    when /the admin edit configuration page/
      edit_admin_configuration_path
    when /the admin configuration page/
      admin_configuration_path

    when /the recycle bin page/
      deleted_items_path

    when /the new search page/
      new_search_path
    when /the search results page/
      search_path

    when /the accept invitation page/
      invitation = model!('invitation')
      new_user_path(:invitation_code => invitation.code)
    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    # added by script/generate pickle path

    when /^#{capture_model}(?:'s)? page$/                           # eg. the forum's page
      path_to_pickle $1

    when /^#{capture_model}(?:'s)? #{capture_model}(?:'s)? page$/   # eg. the forum's post's page
      path_to_pickle $1, $2

    when /^#{capture_model}(?:'s)? #{capture_model}'s (.+?) page$/  # eg. the forum's post's comments page
      path_to_pickle $1, $2, :extra => $3                           #  or the forum's post's edit page

    when /^#{capture_model}(?:'s)? (.+?) page$/                     # eg. the forum's posts page
      path_to_pickle $1, :extra => $2                               #  or the forum's edit page

    when /^the (.+?) page$/                                         # translate to named route
      send "#{$1.downcase.gsub(' ','_')}_path"
  
    # end added by pickle path

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
