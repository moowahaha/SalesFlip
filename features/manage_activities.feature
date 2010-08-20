Feature: Manage activities
  In order to keep track of what they have done, and easily return to past items
  A User
  wants to keep an activity history

  Scenario: Activities on the dashboard
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And an activity exists with subject: erich, action: "Viewed", user: annika
    When I am on the dashboard page
    Then I should see "annika.fleischer@1000jobboersen.de"
    And I should see "created lead"
    And I should not see "viewed lead"

  Scenario: Private activity (in)visibility on the dashboard
    Given I am registered and logged in as annika
    And Annika has invited user: "benny"
    And a lead: "erich" exists with user: benny, permission: "Private"
    When I go to the dashboard page
    Then I should not see "created lead"

  Scenario: Shared activity (in)visibility on the dashboard
    Given I am registered and logged in as annika
    And Annika has invited user: "benny"
    And a lead: "erich" exists with user: benny
    And a lead: "markus" exists with user: benny
    And erich is shared with annika
    And markus is not shared with annika
    When I go to the dashboard page
    Then I should see "Erich"
    And I should not see "Markus"

  Scenario: Viewing an email activity
    Given I am registered and logged in as annika
    And a lead: "erich" exists with user: annika
    And an email: "erich_offer_email" exists with user: annika, commentable: lead, subject: "test email"
    When I go to the dashboard page
    And I follow "test email"
    Then I should be on the lead's page
    
