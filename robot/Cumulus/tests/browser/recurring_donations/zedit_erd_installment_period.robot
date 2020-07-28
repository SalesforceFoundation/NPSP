*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable RD2
Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Setup Test Data
        #Create a Recurring Donation type Open and installment period Monthly Associated To a contact using API
        &{contact1_fields}=   Create Dictionary                     Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERD Open Recurring Donation
        ...                                                         npe03__Installment_Period__c=Monthly
        ...                                                         npe03__Amount__c=100
        ...                                                         npe03__Open_Ended_Status__c=Open
        ...                                                         Status__c=Active
        ...                                                         Day_of_Month__c=2
        ...                                                         InstallmentFrequency__c=1
        ...                                                         PaymentMethod__c=Credit Card

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}


*** Test Cases ***

Edit Installment Period For An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test edits the recurring
     ...                          donation period to advanced and frequency to every 3 month. Verifies the current year
     ...                          and next year values get updated according to the payment period selected. Another edit
     ...                          is made to then adjust the payment installment to every 8 weeks and validate the current
     ...                          and next year payments.


    [tags]                                  unstable               W-042701           feature:RD2

    Go To Page                              Listing                                   npe03__Recurring_Donation__c

    Click Object Button                     New
    Wait For Modal                          New                                       Recurring Donation
    # Reload page is a temporary fix till the developers fix the ui-modal
    Reload Page

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    Edit Recurring Donation Status
    ...                                     Recurring Period=Advanced
    ...                                     Every=3

    #Open NPSP Settings and run Recurring Donations Batch job for the payment values to get updated
    Run Recurring Donations Batch           RD2

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    # validate recurring donation statistics current and next year values
    Validate Field Values Under Section     Statistics
    ...                                     Current Year Value=$200.00
    ...                                     Next Year Value=$400.00
    # Update the payment installment period to every eight weeks
    Edit Recurring Donation Status
    ...                                     Recurring Period=Advanced
    ...                                     Every=8
    ...                                     Installment Period=Weekly
    #Open NPSP Settings and run Recurring Donations Batch job for the payment values to get updated
    Run Recurring Donations Batch           RD2
    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]

    # validate recurring donation statistics current and next year values
    Validate Field Values Under Section     Statistics
    ...                                     Current Year Value=$300.00
    ...                                     Next Year Value=$700.00