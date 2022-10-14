Feature: Agent's dashboard actions

  Background:
    Given default agent's dashboard

  Scenario: Agent clicks reply to the task and state changed to open
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And the task state should be "new"
    And I am on agent dashboard page
    When I click on "Reply"
    And I wait until all Ajax requests are complete
    Then the task state should be "open"
    And I should see 0 tasks

  Scenario: Agent sends reply to the task and select waiting state for task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And the task state should be "new"
    And I am on agent dashboard page
    When I click on "Reply"
    And I wait until all Ajax requests are complete
    Then the task state should be "open"
    And I fill in reply form with "My reply text"
    And I click on "Reply" within "#reply-form-container"
    And I wait until all Ajax requests are complete
    Then I should see text "My reply text"
    And I should see text "Message sent to"
    And task should have 2 messages
    And I should see a bootbox dialog
    When I choose "pause" state in bootbox dialog
    And I wait until all Ajax requests are complete
    And the task state should be "waiting"

  Scenario: Agent sends reply to the task and select close state for task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And the task state should be "new"
    And I am on agent dashboard page
    When I click on "Reply"
    And I wait until all Ajax requests are complete
    Then the task state should be "open"
    And I fill in reply form with "My reply text"
    And I click on "Reply" within "#reply-form-container"
    And I wait until all Ajax requests are complete
    Then I should see text "My reply text"
    And I should see text "Message sent to"
    And task should have 2 messages
    And I should see a bootbox dialog
    And I choose "close" state in bootbox dialog
    And I wait until all Ajax requests are complete
    And the task state should be "ready"

  Scenario: Agent sends reply to the task and select new state for task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And the task state should be "new"
    And I am on agent dashboard page
    When I click on "Reply"
    And I wait until all Ajax requests are complete
    Then the task state should be "open"
    And I fill in reply form with "My reply text"
    And I click on "Reply" within "#reply-form-container"
    And I wait until all Ajax requests are complete
    Then I should see text "My reply text"
    And I should see text "Message sent to"
    And task should have 2 messages
    And I should see a bootbox dialog
    And I choose "renew" state in bootbox dialog
    And I wait until all Ajax requests are complete
    And the task state should be "new"

  Scenario: Agent sends forward message to the task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    Given I am on agent dashboard page
    When I click on "Forward"
    And I wait until all Ajax requests are complete
    Then the task state should be "open"
    And I fill in "reply[to]" within "#forward-form-container" with "blauser@blaaa.com"
    And I click on "Forward" within "#forward-form-container"
    And I wait until all Ajax requests are complete
    Then I should see text "Message sent to blauser@blaaa.com"
    And task should have 2 messages
    And I choose "close" state in bootbox dialog
    And I wait until all Ajax requests are complete
    And the task state should be "ready"
    And I click on "Internal Communications"
    And I should see text "Fwd: Bla title"
    And I should see text "Hehe text goes here"
    And the task should have 1 internal message

  Scenario: Agent sends SMS message in the task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    Given I am on agent dashboard page
    When I click on "Send SMS"
    And I wait until all Ajax requests are complete
    And I fill in "reply[to]" within "#sms-form-container" with "+358401234000"
    And I fill in "reply[description]" within "#sms-form-container" with "Test SMS text goes here"
    And I click on "Send SMS" within "#sms-form-container"
    And I wait until all Ajax requests are complete
    Then I should see text "SMS sent to +358401234000"
    And I should see text "Test SMS text goes here"
    And the task should have 2 messages
    And the task should have 1 sms message

  Scenario: Agent changes state of a task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    Given I am on agent dashboard page
    When I click on "Task management"
    And I select "Open" from "change_state_to"
    And I wait until all Ajax requests are complete
    Then I should not see text "No tasks available"
    And I should see 0 tasks
    And I select "Open" from task states dropdown
    Then I should see 1 task

  Scenario: Agent moves task to another service channel
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    Given I am on agent dashboard page
    When I click on "Task management"
    And I select "Test service channel" from "move_to_service_channel"
    And I wait until all Ajax requests are complete
    Then I should see text 'Moved task to service channel "Test service channel"'
    And the task should belong to the service channel "Test service channel"
