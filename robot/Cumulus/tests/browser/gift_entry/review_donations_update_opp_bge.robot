*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]      Creates the contact and opportunity record required for the test
    ...                  along with getting dates and namespace required for test.
    &{CONTACT} =         API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable   &{CONTACT}
    ${FUT_DATE} =        Get Current Date         result_format=%Y-%m-%d    increment=2 days
    Set suite variable   ${FUT_DATE}
    ${CUR_DATE} =        Get Current Date         result_format=%Y-%m-%d
    Set suite variable   ${CUR_DATE}
    &{OPPORTUNITY} =     API Create Opportunity   ${CONTACT}[AccountId]              Donation
    ...                  StageName=Prospecting
    ...                  Amount=100
    ...                  CloseDate=${FUT_DATE}
    ...                  npe01__Do_Not_Automatically_Create_Payment__c=false
    ...                  Name=${CONTACT}[Name] Donation
    Set suite variable   &{OPPORTUNITY}
    &{PAYMENT} =         API Query Record         npe01__OppPayment__c      npe01__Opportunity__c=${OPPORTUNITY}[Id]
    Set suite variable   &{PAYMENT}
    ${UI_DATE} =         Get Current Date                   result_format=%b %-d, %Y
    Set suite variable   ${UI_DATE}
    ${NS} =              Get NPSP Namespace Prefix
    Set suite variable   ${NS}


*** Test Cases ***
Review Donation And Update Opportunity For Batch Gift
    [Documentation]                      Create a contact with open opportunity (with payment record) via API. Create a batch
    ...                                  with default template and donor as contact. Verify review donations modal has
    ...                                  update opportunity disabled. Create a new payment record for opp via API and verify
    ...                                  update opp link is enabled. Change date to today and amount less than opp amount, process gift.
    ...                                  Verify opportunity is closedwon, amount and date match with values entered on form but
    ...                                  no new payment created or existing payment records are not updated.
    [tags]                               unstable      feature:GE                    W-042803
    #verify Review Donations link is available and update a payment link is active and update opportunity is disabled
    Go To Page                           Landing                       GE_Gift_Entry
    Current Page Should Be               Landing                       GE_Gift_Entry
    Click Link                           Templates
    Select Template Action               Default Gift Entry Template   Edit
    Current Page Should Be               Template                      GE_Gift_Entry
    Click Gift Entry Button              Next: Form Fields
    Click Gift Entry Button              Next: Batch Settings
    Add Batch Table Columns              Donor Name     Donation Name       Status      Failure Information    Donation Date   Donation Amount
    Click Gift Entry Button              Save & Close
    Current Page Should Be               Landing                       GE_Gift_Entry
    Create Gift Entry Batch              Default Gift Entry Template   ${CONTACT}[Name]Automation Batch
    Current Page Should Be               Form                          Gift Entry
    ${batch_id} =                        Save Current Record ID For Deletion     ${NS}DataImportBatch__c
    Fill Gift Entry Form
    ...                                  Donor Type=Contact1
    ...                                  Existing Donor Contact=${CONTACT}[Name]
    Click Button                         Review Donations
    Wait Until Modal Is Open
    Verify Link Status
    ...                                  Update this Payment=enabled
    ...                                  Update this Opportunity=disabled
    #create a new payment for same opp and verify update opportunity link is enabled
    &{new_payment} =                     API Create Payment            ${OPPORTUNITY}[Id]
    ...                                  npe01__Payment_Amount__c=50.0
    ...                                  npe01__Scheduled_Date__c=${CUR_DATE}
    Reload Page
    Current Page Should Be               Form                          Gift Entry
    Fill Gift Entry Form
    ...                                  Donor Type=Contact1
    ...                                  Existing Donor Contact=${CONTACT}[Name]
    Click Button                         Review Donations
    Wait Until Modal Is Open
    Verify Link Status                   Update this Opportunity=enabled
    Click Button                         Update this Opportunity
    Wait Until Modal Is Closed
    #update opportunity with new values
    Fill Gift Entry Form
    ...                                  Donation Amount=80
    ...                                  Donation Date=Today
    Click Button                         Save & Enter New Gift
    #verify donation date and amount values changed on table
    Verify Gift Count                    1
    Verify Table Field Values            Batch Gifts
    ...                                  Donor Name=${CONTACT}[Name]
    ...                                  Donation Amount=$80.00
    ...                                  Donation Name=${OPPORTUNITY}[Name]
    ...                                  Donation Date=${UI_DATE}
    Scroll Page To Location              0      0
    Click Gift Entry Button              Process Batch
    Wait Until BGE Batch Processes       ${CONTACT}[Name]Automation Batch
    #verify opportunity record is updated with new amount and date and is closed won
    Verify Expected Values               nonns                          Opportunity    ${OPPORTUNITY}[Id]
    ...                                  Amount=80.0
    ...                                  CloseDate=${CUR_DATE}
    ...                                  StageName=Closed Won
    #verify new payment is not created and existing payment records are not updated
    Verify Record Count For Object       npe01__OppPayment__c           2
    ...                                  npe01__Opportunity__c=${OPPORTUNITY}[Id]
    Verify Expected Values               nonns                          npe01__OppPayment__c    ${PAYMENT}[Id]
    ...                                  npe01__Payment_Amount__c=100.0
    ...                                  npe01__Scheduled_Date__c=${FUT_DATE}
    ...                                  npe01__Paid__c=False
    Verify Expected Values               nonns                          npe01__OppPayment__c    ${new_payment}[Id]
    ...                                  npe01__Payment_Amount__c=50.0
    ...                                  npe01__Scheduled_Date__c=${CUR_DATE}
    ...                                  npe01__Paid__c=False

