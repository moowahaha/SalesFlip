Feature: Manage users
  In order to manage their personal details and settings
  A User
  wants to manage themselves

  Scenario: Viewing your profile
    Given I am registered and logged in as annika
    And I am on the dashboard page
    When I follow "profile"
    Then I should see "annika.fleischer@1000jobboersen.de"
    And I should see "My Profile"
    And I should see "dropbox@"
    And an activity should not exist

  Scenario: Inviting a user
    Given I am registered and logged in as annika
    And I am on the dashboard page
    And I follow "users"
    And I follow "invitations"
    And I follow "new"
    When I fill in "invitation_email" with "werner@1000jobboersen.de"
    And I select "Freelancer" from "invitation_user_type"
    And I press "invitation_submit"
    Then I should be on the invitations page
    And I should see "werner@1000jobboersen.de"
    And 1 invitations should exist with email: "werner@1000jobboersen.de"

  Scenario: Accepting an invitation
    Given I have an invitation
    And I go to the accept invitation page
    And I fill in "user_username" with "Werner"
    And I fill in "user_password" with "password"
    And I fill in "user_password_confirmation" with "password"
    When I press "user_submit"
    Then 1 users should exist with username: "Werner"
    And I should be on the new user session page

  Scenario: Accepting a freelancer invitation
    Given I have a Freelancer invitation
    And I go to the accept invitation page
    And I fill in "user_username" with "Werner"
    And I fill in "user_password" with "password"
    And I fill in "user_password_confirmation" with "password"
    When I press "user_submit"
    Then 1 freelancers should exist with username: "Werner"
    And I should be on the new user session page

  Scenario: Accepted an invitation with errors
    Given I have an invitation
    And I go to the accept invitation page
    When I press "user_submit"
    Then I should be on the users page
    And I should see "can't be blank"

  Scenario: Inviting a user as a freelancer
    Given a user: "annika" exists
    And I have accepted an invitation from annika
    When I go to the new invitation page
    Then I should be on the dashboard page

  Scenario: Viewing invitations as a freelancer
    Given a user: "annika" exists
    And I have accepted an invitation from annika
    When I go to the invitations page
    Then I should be on the dashboard page

  Scenario: Viewing users as a freelancer
    Given a user: "annika" exists
    And I have accepted an invitation from annika
    When I go to the users page
    Then I should be on the dashboard page

  Scenario: Navigation as a freelancer
    Given a user: "annika" exists
    And I have accepted an invitation from annika
    When I am on the dashboard page
    Then I should not see "Users"
    And I should not see "invitations"
