*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/EngagementTemplatePageObject.py
...             robot/Cumulus/resources/CreateEngTemplatePageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   engagement  engagement_data=${engagement_fields}

*** Variables ***
${task1}  Task_1
${task2}  Task_2
${sub_task1}  subtask1
&{contact1_fields}  Email=test@example.com
&{engagement_fields}  Name=AutomationTestPlan
&{edit_fields}  Name=testplan1    task1=Task_1    task2=Task_2


*** Test Cases ***

Create Engagement Plan And Edit the Plan
    [Documentation]                      Create an engagement plan , Edit the Engagement plan and add tasks
    ...                                  Verify the engagement plan added appears in the list with the edited
    ...                                  tasks.

    Go To Page                                        Detail
    ...                                               EngagementTemplate
    ...                                               object_id=${data}[engagement][Id]
    Click Element With Locator                        link-contains            more actions
    Click Link                                        link=Edit
    Current Page Should Be                            Custom                   CreateEngagement
    Populate Values For Engagement Template           Edit                     ${edit_fields}
    Go To Page                                        Detail
    ...                                               EngagementTemplate
    ...                                               object_id=${data}[engagement][Id]
    Check Field Value                                 Engagement Plan Template Name    AutomationTestPlan
    Select Tab                                        Related
    Check Related List Values                         Engagement Plan Tasks      ${task1}  ${task2}
