@realtime
Feature: Agent's Dashboard Real-Time updates
  Background:
    Given default agent's dashboard
    And second agent exists

  Scenario: Agent's received new tasks into browser
    Given I am on agent dashboard page
    Then I should see text "No tasks available"
    And there exists a task with title "Another task" and text "Bla bla text"
    And all background jobs finished
    And I should see text "Another task"
    And I should see 1 tasks

  Scenario: Task was removed from agent's dashboard when it was switched to open state by another user
    Given there exists a task with title "Another task" and text "Bla bla text"
    And all background jobs finished
    And I am on agent dashboard page
    And I should see 1 tasks
    When state changed to "open" by second agent for task with title "Another task"
    When I click on "Reply"
    And I wait until all Ajax requests are complete
    And I should see bootbox alert what task in use
    And I should see 0 task
    And I should see text "No tasks available"
    When I select "Ready" from task states dropdown
    And I should see 0 task
    And I should see text "No tasks available"

#  @selenium
#  Scenario: Task was not removed from agent's dashboard when it was switched to open state by another user
#    Given there exists a task with title "Another task" and text "Bla bla text"
#    And all tasks is visible for agent
#    And I am on agent dashboard page
#    And I should see 1 tasks
#    And push to browser is stubbed
#    When state changed to "open" by second agent for task with title "Another task"
#    And I should see 1 tasks
#    When I click on "Task management"
#    And I select "Open" from "change_state_to"
#    And I wait until all Ajax requests are complete
#
