*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/GAUPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Sets test data contact and an opportunity for the contact
# Sets test data for two GAUs
Setup Test Data
    Setupdata   contact                  ${contact1_fields}     ${opportunity_fields}
    setupdata   gau1                     gau_data=${gau1_fields}
    setupdata   gau2                     gau_data=${gau2_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Test GAU donation   Amount=100  StageName=Closed Won
&{gau1_fields}           Name=This is Gau1
&{gau2_fields}           Name=This is Gau2


*** Test Cases ***
Assign GAU to Opportunity
    [Documentation]                      Create an opportunity associated to a contatct. Create two GAUs Set
    ...                                  Set GAU Unit Allocations and assign them to the opportunity.

    [tags]                               W-039818                 feature:GAU               unstable           notonfeaturebranch

    Go To Page                           Detail
    ...                                  Opportunity
    ...                                  object_id=${data}[contact_opportunity][Id]
    Select Tab                           Related
    Click Special Related List Button    GAU Allocations         Manage Allocations
    Current Page Should Be               Custom                  ManageAllocations
    Set Gau Allocation
    ...                                  General Accounting Unit 0=${data}[gau1][Name]
    ...                                  Percent 0=50
    Click Link                           Add Row
    Set Gau Allocation
    ...                                  General Accounting Unit 1=${data}[gau2][Name]
    ...                                  Amount 1=20
    Click Button                         Save
    Current Page Should Be               Details                 Opportunity
    Validate Related Record Count        GAU Allocations         2

