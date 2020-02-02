*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/EngagementTemplatePageObject.py

...             robot/Cumulus/resources/NPSP.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   contact   contact_data=${contact1_fields}    engagement_data=${engagement_fields}    task_data=${task_fields}

*** Variables ***
&{contact1_fields}  Email=test@example.com
&{engagement_fields}  Name=testplan1
&{task_fields}  Task1=Task_1    Task2=Task_2


*** Test Cases ***

Delete An Engagement Plan
    [Documentation]                      Create a contact with an engagement plan set
    ...                                  Navigate to the contact details page and delete the engagement plan
    ...                                  Verify that there are no engagement plans for the contact

    Go To Page                                          Details
    ...                                                 Contact
    ...                                                 object_id=${data}[contact][Id]
    Select Tab                                          Related
    ${plan_num}    Verify Eng Plan Exists               Engagement Plans    True

    Click Related Item Popup Link                       Engagement Plans    ${plan_num}    Delete
    Click Modal Button                                  Delete
    Validate Related Record Count                       Engagement Plans       0
    Scroll Page To Location                             0                      0
    Check Activity Tasks                                Task_1                Task_2


