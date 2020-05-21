*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/CustomizableRollupsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Customizable Rollups
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Customizable rollup test $3000 Donation   Amount=3000  StageName=Closed Won  npe01__Do_Not_Automatically_Create_Payment__c=false

***Keywords***
# creates test data a contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}     ${opportunity_fields}
    ${date} =   Get Current Date    increment=1096 days       result_format=%-m/%-d/%Y
    Log To Console  ${date}
    Set suite variable    ${date}


*** Test Cases ***

Calculate CRLPs for Total Gifts 3 Years Ago
    [Documentation]             This test case checks if advanced mapping is enabled. If already enabled 
    ...                         then throws an error and if not, enables Advanced Mapping for Data Imports  
    [tags]                      feature:Customizable Rollups
    Load Page Object            Custom   CustomRollupSettings
    Navigate To Crlpsettings
    Clone Rollup                Contact: Total Gifts Two Years Ago
    ...                                                   Target Object=Contact
    ...                                                   Target Field=Total Gifts Three Years Ago
    ...                                                   Description=The total of all gifts three calendar years ago where the Contact is the Opportunity Primary Contact.
    ...                                                   Operation=Sum
    ...                                                   Years Ago=3 Years Ago

# Navigate to Contact page and run recalculate rollups option
    Go To Page                                            Details
    ...                                                   Contact
    ...                                                   object_id=${data}[contact][Id]
    Waitfor Actions Dropdown And Click Option             Recalculate Rollups
    Wait Until Loading Is Complete
