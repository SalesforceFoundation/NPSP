*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

Setup Test Data
    &{contact1_fields}=   Create Dictionary                     Email=test@example.com
    &{recurringdonation_fields} =	Create Dictionary           Name=Julian Recurring Donation
            ...                                                 npe03__Installment_Period__c=Monthly
            ...                                                 npe03__Amount__c=1200
            ...                                                 npe03__Installments__c=12
            ...                                                 npe03__Schedule_Type__c=Divide By

    Setupdata   contact         ${contact1_fields}    recurringdonation_data=${recurringdonation_fields}

*** Test Cases ***

Create Fixed Length Recurring Donation Divide By
    [Documentation]              This test verifies that Opportunities with the proper divided amount are created for a Recurring Donation.
    [tags]                      feature:Recurring Donations     unit

    #Find 1st Opportunity for Recurring Donation and Check Amount
    @{opportunity1} =                        API Query Installment      ${data}[contact_rd][Id]     (1 of 12)
    Go To Page                               Details                    Opportunity                 object_id=${opportunity1}[0][Id]
    Select Tab                               Details
    Navigate To And Validate Field Value     Amount                     contains                    $100.00

    #Find 2nd Opportunity for Recurring Donation and Check Amount
    @{opportunity2} =                        API Query Installment      ${data}[contact_rd][Id]     (2 of 12)
    Go To Page                               Details                    Opportunity                 object_id=${opportunity2}[0][Id]
    Select Tab                               Details
    Navigate To And Validate Field Value     Amount                     contains                    $100.00






 