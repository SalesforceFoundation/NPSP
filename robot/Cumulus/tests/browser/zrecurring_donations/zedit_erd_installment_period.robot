*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
        ${NS} =             Get NPSP Namespace Prefix
        Set Suite Variable  ${NS}
        #Create a Recurring Donation type Open and installment period Monthly Associated To a contact using API
        &{contact1_fields}=   Create Dictionary                     Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERD Open Recurring Donation
        ...                                                         npe03__Installment_Period__c=Monthly
        ...                                                         npe03__Amount__c=100
        ...                                                         npe03__Open_Ended_Status__c=Open
        ...                                                         ${NS}Status__c=Active
        ...                                                         ${NS}Day_of_Month__c=${day_of_month}
        ...                                                         ${NS}InstallmentFrequency__c=1
        ...                                                         ${NS}PaymentMethod__c=Credit Card

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}
        ${date} =                  Get Current Date      result_format=%-m/%-d/%Y
        Set Suite Variable  ${date}


*** Variables ***

${day_of_month}  2

*** Test Cases ***

Edit Installment Period For An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test edits the recurring
     ...                          donation period to advanced and frequency to every 3 month. Verifies the current year
     ...                          and next year values get updated according to the payment period selected. Another edit
     ...                          is made to then adjust the payment installment to every 8 weeks and validate the current
     ...                          and next year payments.


    [tags]                                  feature:RD2      unstable   api

    Go To Page                              Listing                                   npe03__Recurring_Donation__c
    Current Page Should be                  Listing                                   npe03__Recurring_Donation__c
    Click Link                              New
    Wait For Rd2 Modal
    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Current Page Should be                  Details                                   npe03__Recurring_Donation__c

    Edit Recurring Donation Status
    ...                                     Recurring Period=Advanced
    ...                                     Every=3

    #Open NPSP Settings and run Recurring Donations Batch job for the payment values to get updated
    Run Recurring Donations Batch           RD2

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Current Page Should be                  Details                                   npe03__Recurring_Donation__c
    # validate recurring donation statistics current and next year values
    Validate Current And Next Year values   100

    # Update the payment installment period to every eight weeks
    Edit Recurring Donation Status
    ...                                     Every=8
    ...                                     Installment Period=Weekly
    #Open NPSP Settings and run Recurring Donations Batch job for the payment values to get updated
    Run Recurring Donations Batch           RD2
    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Current Page Should be                  Details                                   npe03__Recurring_Donation__c
    # validate recurring donation statistics current and next year values
    Validate Current And Next Year values   100