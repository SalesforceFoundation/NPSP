*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data

Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
     ${NS} =             Get NPSP Namespace Prefix
     Set Suite Variable  ${NS}
     ${EFFECTIVE_DATE_INITIAL} =           Get Current Date      result_format=%-m/%-d/%Y
     ${DATE}=                              Get current date      result_format=%Y-%m-%d %H:%M:%S.%f      increment=30 days
     ${DATE_TO_UPDATE} =                   Convert Date          ${DATE}                                 result_format=%Y-%m-%d
     ${EFFECTIVE_MODIFIED_DATE}=           Get current date      result_format=%-m/%-d/%Y                increment=30 days
     ${CURRDATE}=                          Get Current Date      result_format=datetime

     Set Suite Variable  ${DATE}
     Set Suite Variable  ${EFFECTIVE_MODIFIED_DATE}
     Set Suite Variable  ${EFFECTIVE_DATE_INITIAL}
     Set Suite Variable  ${DATE_TO_UPDATE}

     &{contact1_fields}=              Create Dictionary          Email=rd2tester@example.com
     &{recurringdonation_fields} =	  Create Dictionary          Name=ERDTest1
     ...                                                         npe03__Installment_Period__c=Monthly
     ...                                                         npe03__Amount__c=100
     ...                                                         npe03__Open_Ended_Status__c=${TYPE}
     ...                                                         ${NS}Status__c=Active
     ...                                                         ${NS}Day_of_Month__c=${DAY_OF_MONTH}
     ...                                                         ${NS}InstallmentFrequency__c=${FREQUENCY}
     ...                                                         ${NS}PaymentMethod__c=${METHOD}

     Setupdata   contact             ${contact1_fields}          recurringdonation_data=${recurringdonation_fields}


*** Variables ***
${FREQUENCY}  1
${DAY_OF_MONTH}  15
${AMOUNT_TO_UPDATE}  150
${METHOD}  Credit Card
${TYPE}    Open

*** Test Cases ***

Edit An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test ensures that when the record
     ...                          is edited and effective date is updated to next month , Verifies that future schedule is shown
     ...                          with the right values reflected. Verifies the current year and future year schedules are updated
     ...                          Verifies the opportunity status
    [tags]                                   feature:RD2    unit

    Go To Page                               Details
    ...                                      npe03__Recurring_Donation__c
    ...                                      object_id=${data}[contact_rd][Id]
    Current Page Should Be                   Details                        npe03__Recurring_Donation__c
    Validate Field Values Under Section
    ...                                      Amount=$100.00
    ...                                      Status=Active
    # Validate the fields under Current Schedule card
    Validate Field Values Under Section      Current Schedule
    ...                                      Amount=$100.00
    ...                                      Payment Method=Credit Card
    ...                                      Effective Date=${EFFECTIVE_DATE_INITIAL}
    ...                                      Installment Period=Monthly
    ...                                      Day of Month=15
    #Query the opportunity ID associated with the recurring donation. Navigate to the opportunity and validate the status
    @{opportunity1} =                        API Query Opportunity For Recurring Donation                   ${data}[contact_rd][Id]
    Store Session Record                     Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                               Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value     Stage                          contains                        Pledged
    #Using backend API update the recurring donation record and modify the startDate field to next month's date
    API Modify Recurring Donation            ${data}[contact_rd][Id]
    ...                                      npe03__Amount__c=${AMOUNT_TO_UPDATE}
    ...                                      ${ns}StartDate__c=${DATE_TO_UPDATE}
    Run Recurring Donations Batch            RD2
    Go To Page                               Details
    ...                                      npe03__Recurring_Donation__c
    ...                                      object_id=${data}[contact_rd][Id]
    Current Page Should Be                   Details                        npe03__Recurring_Donation__c
    # Verify that Future schedule section shows up and the values reflect the changes
    Validate Field Values Under Section      Future Schedule
    ...                                      Amount=$150.00
    ...                                      Payment Method=Credit Card
    ...                                      Effective Date=${EFFECTIVE_MODIFIED_DATE}
    ...                                      Installment Period=Monthly
    ...                                      Day of Month=15
    Go To Page                               Details
    ...                                      npe03__Recurring_Donation__c
    ...                                      object_id=${data}[contact_rd][Id]
    Current Page Should Be                   Details                        npe03__Recurring_Donation__c
    @{opportunity1} =                        API Query Opportunity For Recurring Donation                   ${data}[contact_rd][Id]
    Store Session Record                     Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                               Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Current Page Should Be                   Details                        Opportunity
    Navigate To And Validate Field Value     Stage                          contains                        Pledged