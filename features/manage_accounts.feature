Feature: Manage accounts
  In order to keep track of accounts and associated contacts
  A User
  wants to manage accounts

  Scenario: Filtering Account by owner
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And account: "careermee" exists with user: Annika
    And account: "world_dating" exists with user: Benny
    And I am on the accounts page
    When I check "Assigned to me"
    And I press "filter"
    Then I should be on the accounts page
    And I should see "CareerMee"
    And I should not see "World Dating"

  Scenario: Filtering Account by Account Type
    Given I am registered and logged in as annika
    And Annika has invited Benny
    And account: "careermee" exists with user: Annika, account_type: "Investor"
    And account: "world_dating" exists with user: Annika, account_type: "Competitor"
    And I am on the accounts page
    When I select "Investor" from "account_type_is"
    And I press "filter"
    Then I should be on the accounts page
    And I should see "CareerMee"
    And I should not see "World Dating"

  Scenario: Creating an account
    Given I am registered and logged in as annika
    And I am on the accounts page
    And I follow "new"
    And I fill in "account_name" with "CareerMee"
    When I press "account_submit"
    Then I should be on the account page
    And I should see "CareerMee"
    And a new "Created" activity should have been created for "Account" with "name" "CareerMee"

  Scenario: Editing an account
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika
    And I am on the account's page
    And I follow "Edit Account"
    And I fill in "account_name" with "a test"
    When I press "account_submit"
    Then I should be on the account's page
    And I should see "a test"
    And I should not see "CareerMee"
    And a new "Updated" activity should have been created for "Account" with "name" "a test" and user: "annika"

  Scenario: Editing an account from index page
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika
    And I am on the accounts page
    When I follow the edit link for the account
    Then I should be on the account's edit page

  #Scenario: Deleting an account from the index page
  #  Given I am registered and logged in as annika
  #  And a user: "benny" exists
  #  And benny belongs to the same company as annika
  #  And account: "careermee" exists with user: benny
  #  And I am on the accounts page
  #  When I click the delete button for the account
  #  Then I should be on the accounts page
  #  And I should not see "CareerMee" within "#main"
  #  And a new "Deleted" activity should have been created for "Account" with "name" "CareerMee" and user: "annika"

  Scenario: Viewing accounts
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika, name: "CareerMee"
    And I am on the dashboard page
    When I follow "accounts"
    Then I should see "CareerMee"
    And I should be on the accounts page

  Scenario: Viewing an account
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika, name: "CareerMee"
    And I am on the dashboard page
    And I follow "accounts"
    When I follow "careermee"
    Then I should see "CareerMee"
    And I should be on the account page
    And a new "Viewed" activity should have been created for "Account" with "name" "CareerMee"

  Scenario: Editing an account from the show page
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika
    And I am on the account's page
    When I follow the edit link for the account
    Then I should be on the account's edit page
  
  #Scenario: Deleting an account from the show page
  #  Given I am registered and logged in as annika
  #  And a user: "benny" exists
  #  And account: "careermee" exists with user: benny
  #  And I am on the account's page
  #  When I click the delete button for the account
  #  Then I should be on the accounts page
  #  And I should not see "CareerMee" within "#main"
  #  And a new "Deleted" activity should have been created for "Account" with "name" "CareerMee" and user: "annika"
  
  Scenario: Private account (in)visibility on the accounts page
    Given I am registered and logged in as annika
    And a user: "benny" exists
    And benny belongs to the same company as annika
    And an account: "careermee" exists with user: benny, permission: "Public", name: "CareerMee"
    And an account: "world_dating" exists with user: benny, permission: "Private"
    When I go to the accounts page
    Then I should see "CareerMee"
    And I should not see "World Dating"

  Scenario: Shared lead visibility on accounts page
    Given I am registered and logged in as benny
    And an account: "careermee" exists with user: benny, permission: "Private"
    And user: "annika" exists with email: "annika.fleischer@1000jobboersen.de"
    And annika belongs to the same company as benny
    And I go to the new account page
    And I fill in "account_name" with "World Dating"
    And I select "Shared" from "account_permission"
    And I select "annika.fleischer@1000jobboersen.de" from "account_permitted_user_ids"
    And I press "account_submit"
    And I logout
    And I login as annika
    When I go to the accounts page
    Then I should see "World Dating"
    And I should not see "CareerMee"

  Scenario: Viewing a shared accounts details
    Given I am registered and logged in as annika
    And a user: "benny" exists
    And benny belongs to the same company as annika
    And an account: "careermee" exists with user: benny, name: "CareerMee"
    And careermee is shared with annika
    And I am on the accounts page
    When I follow "careermee"
    Then I should be on the account's page
    And I should see "CareerMee"

  Scenario: Adding a task to an account
    Given I am registered and logged in as annika
    And an account: "careermee" exists with user: annika
    And I am on the account's page
    And I follow "add_task"
    And I follow "preset_date"
    And I fill in "task_name" with "Call to get offer details"
    And I select "As soon as possible" from "task_due_at"
    And I select "Call" from "task_category"
    When I press "task_submit"
    Then I should be on the account's page
    And a task should have been created
    And I should see "Call to get offer details"
  
  Scenario: Marking an account task as completed
    Given I am registered and logged in as annika
    And an account exists with user: annika
    And a task exists with asset: the account, name: "Call to get offer details", user: annika
    And I am on the account's page
    When I check "Call to get offer details"
    And I press "task_submit"
    Then the task "Call to get offer details" should have been completed
    And I should be on the account's page
    And I should not see "Call to get offer details"

  Scenario: Deleting a task
    Given I am registered and logged in as annika
    And an account exists with user: annika
    And a task exists with asset: the account, name: "Call to get offer details", user: annika
    And I am on the account's page
    When I click the delete button for the task
    Then I should be on the account's page
    And a task should not exist
    And I should not see "Call to get offer details"

  Scenario: Adding a comment
    Given I am registered and logged in as annika
    And a account exists with user: annika
    And I am on the account's page
    And I fill in "comment_text" with "This is a good lead"
    When I press "comment_submit"
    Then I should be on the account page
    And I should see "This is a good lead"
    And 1 comments should exist

  # Seems to fail due to a webrat bug
  #Scenario: Adding a comment with an attachment
  #  Given I am registered and logged in as annika
  #  And a account exists with user: annika
  #  And I am on the account's page
  #  And I fill in "comment_text" with "Sent offer"
  #  And I attach the file at "test/upload-files/erich_offer.pdf" to "Attachment"
  #  When I press "comment_submit"
  #  Then I should be on the account page
  #  And I should see "Sent offer"
  #  And I should see "erich_offer.pdf"

  #Scenario: Editing a comment
  #  Given I am registered and logged in as annika
  #  And account: "careermee" exists with user: annika, permission: "Public"
  #  And a comment exists with user: annika, commentable: account, text: "Excellent account!"
  #  And I am on the account's page
  #  When I follow "Edit this Comment"
  #  Then I should be on the comment's edit page
  #  And I fill in "comment_text" with "Excellent account!!!"
  #  When I press "Update Comment"
  #  Then I should be on the account's page
  #  And I should see "Excellent account!!!"

  #Scenario: Deleting a comment
  #  Given I am registered and logged in as annika
  #  And account: "careermee" exists with user: annika, permission: "Public"
  #  And a comment exists with user: annika, commentable: account, text: "Some account this is"
  #  And I am on the account's page
  #  When I click the delete button for the comment
  #  Then I should be on the account's page
  #  And I should not see "Some account this is"

  Scenario: Viewing activites on the show page
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: annika
    And I am on the account's page
    And I follow the edit link for the account
    When I fill in "account_name" with "CareerMe"
    And I press "account_submit"
    Then I should be on the account's page
    And I should see "Updated"
    And I should see "annika.fleischer@1000jobboersen.de"

  Scenario: Exporting Accounts
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: Annika
    And I am on the accounts page
    When I follow "Export this list as a CSV"
    Then I should be on the export accounts page

  Scenario: Adding a contact to an existing account
    Given I am registered and logged in as annika
    And account: "careermee" exists with user: Annika
    And I am on the account's page
    When I follow "Add Contact"
    And I fill in "First Name" with "Matt"
    And I fill in "Last Name" with "Beedle"
    And I press "contact_submit"
    Then I should be on the account's page
    And I should see "Matt Beedle"
