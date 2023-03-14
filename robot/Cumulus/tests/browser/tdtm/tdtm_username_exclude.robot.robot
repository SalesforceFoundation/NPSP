*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/TriggerHandlerPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
API Modify Trigger Handler
    [Arguments]                  ${triggerhandler_id}           &{fields}
    ${ns} =                      Get NPSP Namespace Prefix
    Salesforce Update            ${ns}Trigger_Handler__c        ${triggerhandler_id}
    ...                          &{fields}
    @{records} =                 Salesforce Query               ${ns}Trigger_Handler__c
    ...                          select=Id
    ...                          Id=${triggerhandler_id}
    &{triggerhandler} =          Get From List                  ${records}                    0
    [return]                     &{triggerhandler}

*** Test Cases ***
Update a Trigger Handler to Exclude a Username
    [Documentation]    This test case verifies that when a username is added to a Trigger Handler		
    ...                record for exclusion that triggers indeed do not run for that User.
    [Tags]              quadrant:q3

    # Create an Account so Trigger Handler records are created
    &{account} =                 API Create Organization Account

    # Navigate to Recurring Donation Trigger Handler Record and exclude Scratch User
    ${ns} =                      Get NPSP Namespace Prefix
    @{triggerhandler} =          Salesforce Query               ${ns}Trigger_Handler__c
    ...                          select=Id
    ...                          ${ns}Class__c=RD_RecurringDonations_TDTM
    @{scratchuser} =             Salesforce Query               User
    ...                          select=Username
    ...                          Name=User User
    Go To Page                   Details            Trigger_Handler__c            object_id=${triggerhandler}[0][Id]
    ${uppercaseusername} =       Convert To Uppercase           ${scratchuser}[0][Username]
    API Modify Trigger Handler   ${triggerhandler}[0][Id]       ${ns}Usernames_to_Exclude__c=${uppercaseusername}

    # Create a Recurring Donation and verify no Opportunities are created
    &{contact} =                 API Create Contact             Email=jjoseph@robot.com
    Go To Page                   Details            Contact           object_id=${contact}[Id]
    &{recurringdonation} =       API Create Recurring Donation  npe03__Contact__c=${contact}[Id]
    ...                          Name=Julian Recurring Donation
    ...                          npe03__Amount__c=1200
    ...                          npe03__Installments__c=12
    ...                          npe03__Schedule_Type__c=Divide By
    ...                          npe03__Installment_Period__c=Monthly
    Go To Page                   Details           npe03__Recurring_Donation__c           object_id=${recurringdonation}[Id]
    Go To Page                   Details           Contact           object_id=${contact}[Id]

    #Verify no Opportunities were created
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[Id]
    Should be empty              ${opportunity}

    # Assist Teardown by Removing Excluded Username
    API Modify Trigger Handler   ${triggerhandler}[0][Id]       ${ns}Usernames_to_Exclude__c=