Feature: Agent logging into the system

  Background:
    Given agent exists with email "bla@bla.com" and password "password"

  Scenario: Agent logs in with correct username and password
    Given I am on login page
    When I fill "user[email]" with "bla@bla.com"
    When I fill "user[password]" with "password"
    When I press "Login"
    Then I should be on agent dashboard

  Scenario: Agent tries to log in with incorrect password
    Given I am on login page
    When I fill "user[email]" with "bla@bla.com"
    When I fill "user[password]" with "asdfasdf"
    When I press "Login"
    Then I should be on login page
    And I should see text "Invalid email or password"

  Scenario: Agent logs in with token
    Given agent is logged in with token
    Then I should be on agent dashboard
