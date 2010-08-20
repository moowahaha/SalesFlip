Feature: Manage registrations
  In order to create an account
  A user
  wants to register

  Scenario: Registering
    Given I go to the registration page
    And I fill in the registration form
    When I press "user_submit"
    Then a new user should have been created
    And I should be on the new user session page
