Feature: I as company manager want to manage service channels

  Background:
    Given manager exists with email "bla@bla.com" and password "password"
    And there exists location with name "Test Location"
    And manager is logged in

  Scenario: Manager can create new service channel
    Given I am on new service channel page
    When I fill "service_channel[name]" with "Test Service Channel"
    And I fill "service_channel[yellow_alert_days]" with "1"
    And I fill "service_channel[yellow_alert_hours]" with "1"
    And I fill "service_channel[red_alert_days]" with "1"
    And I fill "service_channel[red_alert_hours]" with "1"
    And I checked "Test Location" location
    And I press "Save details"
    Then I redirected to service channel "Test Service Channel"
