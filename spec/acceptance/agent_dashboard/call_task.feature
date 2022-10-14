Feature: Agent dashboard call task actions

  Background:
    Given default agent's dashboard

  Scenario: Agent locks call task
    Given there exists a new call task with title "Unanswered call" and text "Unanswered call +358405651099"
    Given I am on agent dashboard page
    When I click on "Lock"
    And I wait until all Ajax requests are complete
    And I select "Waiting" from task states dropdown
    Then I should see 1 task

  Scenario: Agent closes call task
    Given there exists a new call task with title "Unanswered call" and text "Unanswered call +358405651099"
    Given I am on agent dashboard page
    When I click on "Mark as done"
    And I should see an confirm notification
    When I confirm notification
    And I wait until all Ajax requests are complete
    Then I should see 0 tasks
    And I select "Ready" from task states dropdown
    Then I should see 1 task
    And the task state should be "ready"

  Scenario: Agent should be able to reopen call task
    Given there exists a ready call task with title "Unanswered call" and text "Unanswered call +358405651099"
    And task with title "Unanswered call" is assigned to agent
    Given I am on agent dashboard page
    And I select "Ready" from task states dropdown
    When I click on "Task management"
    And I select "Reopen" from "change_state_to"
    And I wait until all Ajax requests are complete
    Then I should not see text "No tasks available"
    And I should see 0 tasks
    And I select "Open" from task states dropdown
    Then I should see 1 task
    And the task state should be "open"
