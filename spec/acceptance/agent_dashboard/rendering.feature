Feature: Agent dashboard rendering

  Background:
    Given default agent's dashboard

  Scenario: Agent loads empty dashboard (with no tasks available)
    Given I am on agent dashboard page
    Then I should see text "No tasks available"

  Scenario: Agent loads dashboard and sees 2 tasks
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And there exists a task with title "Another task" and text "Bla bla text"
    Given I am on agent dashboard page
    Then I should not see text "No tasks available"
    And I should see text "Bla title"
    And I should see text "Another task"

  Scenario: Agent selects closed tasks in filter and sees one task
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And there exists a task with title "Another task" and text "Bla bla text"
    And there exists a ready task with title "Closed bla task" and text "Solved this task"
    And task with title "Closed bla task" is assigned to agent
    Given I am on agent dashboard page
    And I should see 2 tasks
    And I should see text "Bla title"
    And I should see text "Another task"
    When I select "Ready" from task states dropdown
    And I should see 1 task
    And I should see text "Closed bla task"

  Scenario: Agent types in search box and the task list is filtered
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And there exists a task with title "Another task" and text "Bla bla text"
    And there exists a task with title "Yet another bla task" and text "foo baz bar"
    Given I am on agent dashboard page
    When I type "Heh" in search form
    And I should see 1 task
    And I should see text "Bla title"

  Scenario: Agent clicks on differnt tasks and sees tasks messages
    Given there exists a task with title "Bla title" and text "Hehe text goes here"
    And there exists a task with title "Another task" and text "Bla bla text"
    And there exists a task with title "Yet another bla task" and text "foo baz bar"
    Given I am on agent dashboard page
    When I click task titled "Another task"
    Then I should see text "Bla bla text"
    When I click task titled "Bla title"
    Then I should see text "Hehe text goes here"
