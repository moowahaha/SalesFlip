Feature: Manage admins
  In order to access restricted functions
  An Admin
  wants to have an administration section

  Scenario: Logging in as admin
    Given an admin: "matt" exists
    And I am on the admin login page
    And I fill in "admin_email" with "matt.beedle@1000jobboersen.de"
    And I fill in "admin_password" with "password"
    When I press "admin_submit"
    Then I should be on the admin dashboard page

  Scenario: Logging out as admin
    Given an admin: "matt" exists
    And I login as an administrator: "matt"
    And I am on the admin dashboard page
    When I follow "logout"
    Then I should be on the new user session page
