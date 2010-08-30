Feature: Manage leads
  In order to keep track of leads
  A user
  wants manage leads

  Scenario: Accepting a lead
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And all emails have been delivered
    And I am on the leads page
    When I press "accept"
    Then I should be on the lead's page
    And the lead: "erich" should be assigned to annika
    And 0 emails should be delivered

  Scenario: Accepting a lead from the show page
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And I am on the lead's page
    When I press "accept"
    Then I should be on the lead's page
    And the lead: "erich" should be assigned to annika

  Scenario: Creating a lead
    Given I am registered and logged in as annika
    And I am on the leads page
    And all emails have been delivered
    And I follow "new"
    And I fill in "lead_first_name" with "Erich"
    And I fill in "lead_last_name" with "Feldmeier"
    When I press "lead_submit"
    Then I should be on the leads page
    And I should see "Erich Feldmeier"
    And a created activity should exist for lead with first_name "Erich"
    And 0 emails should be delivered

  Scenario: Creating a lead as a freelancer
    Given Carsten Werner exists
    And Carsten Werner is confirmed
    And I am logged in as Carsten Werner
    And I am on the leads page
    And all emails have been delivered
    And I follow "new"
    And I fill in "lead_first_name" with "Erich"
    And I fill in "lead_last_name" with "Feldmeier"
    When I press "lead_submit"
    Then I should be on the leads page
    And 1 leads should exist with first_name: "Erich", last_name: "Feldmeier"
    And I should see "Erich Feldmeier"
    And a created activity should exist for lead with first_name "Erich"
    And 0 emails should be delivered

  Scenario: Logging activity
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead: "erich" exists with user: benny
    And I am on the lead's edit page
    When I press "lead_submit"
    Then an activity should have been created with for lead: "erich" and user: "annika"

  #Scenario: Creating a lead via XML
  #  Given I am registered and logged in as annika
  #  When I POST attributes for lead: "erich" to the leads page
  #  Then 1 leads should exist with assignee_id: nil

  Scenario: Adding a comment
    Given I am registered and logged in as annika
    And a lead exists with user: annika
    And I am on the lead's page
    And I fill in "comment_text" with "This is a good lead"
    When I press "comment_submit"
    Then I should be on the lead page
    And I should see "This is a good lead"
    And 1 comments should exist

  # TODO seems to be a webrat bug breaking this feature
  #Scenario: Adding an comment with an attachment
  #  Given I am registered and logged in as annika
  #  And a lead exists with user: annika
  #  And I am on the lead's page
  #  And I fill in "comment_text" with "Sent offer"
  #  And I attach the file at "test/upload-files/erich_offer.pdf" to "Attachment"
  #  When I press "comment_submit"
  #  Then I should be on the lead page
  #  And I should see "Sent offer"
  #  And I should see "erich_offer.pdf"

  Scenario: Editing a lead
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And I am on the leads page
    And I follow the edit link for the lead
    And I fill in "lead_phone" with "999"
    When I press "lead_submit"
    Then I should be on the leads page
    And a lead should exist with phone: "999"
    And an updated activity should exist for lead with first_name "Erich"

  Scenario: Editing a lead from index page
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And benny belongs to the same company as annika
    And lead: "erich" exists with user: benny
    And I am on the leads page
    When I follow the edit link for the lead
    Then I should be on the lead's edit page

  #Scenario: Deleting a lead from the index page
  #  Given I am registered and logged in as annika
  #  And Annika has invited Benny
  #  And benny belongs to the same company as annika
  #  And a lead "erich" exists with user: benny
  #  And I am on the leads page
  #  When I click the delete button for the lead
  #  Then I should be on the leads page
  #  And lead "erich" should have been deleted
  #  And a new "Deleted" activity should have been created for "Lead" with "first_name" "Erich" and user: "annika"

  Scenario: Leads index when freelance user
    Given a user: "annika" exists
    And I have accepted an invitation from annika
    And a lead: "erich" exists with user: annika
    And a lead: "markus" exists with user: freelancer
    When I am on the leads page
    Then I should not see "Erich"
    And I should see "Markus"
    And I should not see "filter"

  Scenario: Filtering leads
    Given I am registered and logged in as annika
    And a lead exists with user: annika, status: "New", first_name: "Erich"
    And a lead exists with user: annika, status: "Rejected", first_name: "Markus"
    And I go to the leads page
    When I check "New"
    And I press "Filter"
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Filtering unassigned leads
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead exists with user: annika, status: "New", first_name: "Erich"
    And a lead exists with user: annika, status: "New", assignee: benny, first_name: "Markus"
    And I go to the leads page
    When I check "unassigned"
    And I press "filter"
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Filtering leads assigned to me
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead exists with user: annika, status: "New", first_name: "Erich", assignee: annika
    And a lead exists with user: annika, status: "New", first_name: "Markus", assignee: benny
    And I go to the leads page
    When I check "assigned_to"
    And I press "filter"
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Filtering leads by source
    Given I am registered and logged in as annika
    And a lead exists with user: annika, status: "New", first_name: "Erich", source: "Website"
    And a lead exists with user: annika, status: "New", first_name: "Markus", source: "Imported"
    And I go to the leads page
    When I check "source_imported"
    And I press "filter"
    Then I should see "Markus"
    And I should not see "Erich"

  Scenario: Deleted leads
    Given I am registered and logged in as annika
    And a lead: "kerstin" exists with user: annika
    When I am on the leads page
    Then I should not see "Kerstin"

  Scenario: Viewing a lead
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika, source: "Imported"
    And I am on the dashboard page
    And I follow "Leads"
    When I follow "erich-feldmeier"
    Then I should be on the lead page
    And I should see "Erich"
    And a view activity should have been created for lead with first_name "Erich"
    And I should not see "delete" within "#content"

  Scenario: Editing a account from the show page
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika
    And I am on the account's page
    When I follow the edit link for the account
    Then I should be on the account's edit page

  #Scenario: Deleting a lead from the show page
  #  Given I am registered and logged in as annika
  #  And Annika has invited Benny
  #  And a lead "erich" exists with user: benny
  #  And I am on the lead's page
  #  When I click the delete button for the lead
  #  Then I should be on the leads page
  #  And I should not see "Erich" within "#main"
  #  And a new "Deleted" activity should have been created for "Lead" with "first_name" "Erich" and user: "annika"

  Scenario: Adding a task to a lead
    Given I am registered and logged in as annika
    And a lead exists with user: annika
    And I am on the lead's page
    And all emails have been delivered
    And I follow "add_task"
    And I follow "preset_date"
    And I fill in "task_name" with "Call to get offer details"
    And I select "As soon as possible" from "task_due_at"
    And I select "Call" from "task_category"
    When I press "task_submit"
    Then I should be on the lead's page
    And a task should have been created
    And I should see "Call to get offer details"
    And 0 emails should be delivered

  Scenario: Adding a task to an unassigned lead
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead exists with user: Benny, assignee_id: nil
    And I am on the lead's page
    And all emails have been delivered
    And I follow "add_task"
    And I follow "preset_date"
    And I fill in "task_name" with "Call to get offer details"
    And I select "As soon as possible" from "task_due_at"
    And I select "Call" from "task_category"
    When I press "task_submit"
    Then I should be on the lead's page
    And a task should have been created
    And I should see "Call to get offer details"
    And 0 emails should be delivered
    And the lead should be assigned to Annika

  Scenario: Marking a lead as completed
    Given I am registered and logged in as annika
    And a lead exists with user: annika
    And a task exists with asset: the lead, name: "Call to get offer details", user: annika
    And I am on the lead's page
    When I check "Call to get offer details"
    And I press "task_submit"
    Then the task "Call to get offer details" should have been completed
    And I should be on the lead's page
    And I should not see "Call to get offer details"

  Scenario: Deleting a task
    Given I am registered and logged in as annika
    And a lead exists with user: annika
    And a task exists with asset: the lead, name: "Call to get offer details", user: annika
    And I am on the lead's page
    When I click the delete button for the task
    Then I should be on the lead's page
    And a task should not exist
    And I should not see "Call to get offer details"

  Scenario: Rejecting a lead
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead: "erich" exists with user: benny
    And I am on the lead's page
    When I press "Reject"
    Then I should be on the leads page
    And lead "erich" should exist with status: 3
    And a new "Rejected" activity should have been created for "Lead" with "first_name" "Erich" and user: "annika"

  Scenario: Converting a lead to a new account
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And a lead: "erich" exists with user: benny
    And I am on the lead's page
    When I follow "Convert"
    And I fill in "account_name" with "World Dating"
    And I press "convert"
    Then I should be on the account page
    And I should see "World Dating"
    And I should see "Erich"
    And an account should exist with name: "World Dating"
    And a contact should exist with first_name: "Erich"
    And a lead should exist with first_name: "Erich", status: 2
    And a new "Created" activity should have been created for "Contact" with "first_name" "Erich" and user: "annika"
    And a new "Converted" activity should have been created for "Lead" with "first_name" "Erich" and user: "annika"
    And a new "Created" activity should have been created for "Account" with "name" "World Dating" and user: "annika"

  Scenario: Converting a lead to an existing account
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And a account: "careermee" exists with user: annika
    And I am on the lead's page
    When I follow "Convert"
    And I select "CareerMee" from "account_id"
    And I press "convert"
    Then I should be on the account page
    And I should see "CareerMee"
    And I should see "Erich"
    And 1 accounts should exist
    And a new "Converted" activity should have been created for "Lead" with "first_name" "Erich" and user: "annika"

  Scenario: Converting a lead to an existing contact
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika, email: "erich.feldmeier@gmail.com"
    And account: "careermee" exists with user: annika
    And contact: "florian" exists with email: "erich.feldmeier@gmail.com", account: careermee
    And I am on the lead's page
    When I follow "Convert"
    And I press "convert"
    Then I should be on the account page
    And I should see "CareerMee"
    And 1 contacts should exist

  Scenario: Convert page when converting to an existing account
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika, email: "erich.feldmeier@gmail.com"
    And account: "careermee" exists with user: annika
    And contact: "florian" exists with email: "erich.feldmeier@gmail.com", account: careermee
    And I am on the lead's page
    When I follow "Convert"
    Then I should not see "Account Name"
    And I should see "convert"

  Scenario: Trying to convert a lead without entering an account name
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And I am on the lead's page
    When I follow "Convert"
    And I press "convert"
    Then I should be on the lead's promote page

  Scenario: Private lead (in)visiblity on leads page
    Given I am registered and logged in as annika
    And user: "benny" exists
    And benny belongs to the same company as annika
    And a lead: "erich" exists with user: benny, permission: "Private"
    And a lead: "markus" exists with user: benny, permission: "Public"
    When I go to the leads page
    Then I should not see "Erich"
    And I should see "Markus"

  Scenario: Shared lead visibility on leads page
    Given I am registered and logged in as benny
    And a lead: "markus" exists with user: benny, permission: "Private"
    And user: "annika" exists with email: "annika.fleischer@1000jobboersen.de"
    And annika belongs to the same company as benny
    And I go to the new lead page
    And I fill in "lead_first_name" with "Erich"
    And I fill in "lead_last_name" with "Feldmeier"
    And I select "Shared" from "lead_permission"
    And I select "annika.fleischer@1000jobboersen.de" from "lead_permitted_user_ids"
    And I press "lead_submit"
    And I logout
    And I login as annika
    When I go to the leads page
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Shared lead (in)visibility on leads page
    Given I am registered and logged in as annika
    And user: "benny" exists
    And benny belongs to the same company as annika
    And a lead: "erich" exists with user: benny
    And a lead: "markus" exists with user: benny
    And erich is shared with annika
    And markus is not shared with annika
    When I go to the leads page
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Viewing a shared lead details
    Given I am registered and logged in as annika
    And user: "benny" exists
    And benny belongs to the same company as annika
    And a lead: "erich" exists with user: benny
    And erich is shared with annika
    And I am on the leads page
    When I follow "erich-feldmeier"
    Then I should see "Erich"
    And I should be on the lead's page

  Scenario: Actions for a converted lead
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika, status: "Converted"
    When I am on the lead's page
    Then I should not see "Convert" within "a"
    And I should not see "Reject" within "a"

  Scenario: Actions for a rejected lead
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika, status: "Rejected"
    When I am on the lead's page
    Then I should not see "Convert"
    And I should not see "Reject" within "a"

  Scenario: Viewing activites on the show page
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And I am on the lead's page
    And I follow the edit link for the lead
    Then I should be on the lead's edit page
    When I select "Mr" from "lead_salutation"
    And I press "lead_submit"
    Then I should be on the lead's page
    And I should see "Updated"
    And I should see "annika.fleischer@1000jobboersen.de"

  Scenario: Exporting Leads
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: Annika
    When I am on the leads page
    Then I should see "Export this list as a CSV"

  Scenario: Exporting Leads (2)
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: Annika
    And I am on the leads page
    When I follow "Export this list as a CSV"
    Then I should be on the export leads page
