*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/EngagementPlanTemplatesPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Variables ***
${task1}  Task_1
${task2}  Task_2
${name}  AutomationTestPlan


*** Test Cases ***
Create Engagement Plan Template And verify save
    [Documentation]                      Create an engagement plan from the ui. Navigate to engagementplans listings view
    ...                                  View the details of the engagement plan created.

    [tags]                                             feature:Engagements     unstable    api      quadrant:q3

      Go To Page                                       Listing                            Engagement_Plan_Template__c
      Click Special Object Button                      New
      Current Page Should Be                           Home                               Engagement_Plan_Template__c
      Enter Eng Plan Values                            idName                             ${name}
      Enter Eng Plan Values                            idDesc                             This plan is created via Automation
      Click Task Button                                Task 1
      Enter Task Id and Subject                        Task 1                             ${task1}
      Click Task Button                                Task 2
      Enter Task Id and Subject                        Task 2                             ${task2}
      Save Engagement Plan Template
      Current Page Should Be                           Details                            Engagement_Plan_Template__c

     ${ns} =  Get NPSP Namespace Prefix
     Save Current Record ID For Deletion             ${ns}Engagement_Plan_Template__c
     Go To Page                                      Listing                             Engagement_Plan_Template__c
     Click Link                                      link=${name}
     Check Field Value                               Engagement Plan Template Name       ${name}
     Select Tab                                      Related
     Check Related List Values                       Engagement Plan Tasks               ${task1}  ${task2}