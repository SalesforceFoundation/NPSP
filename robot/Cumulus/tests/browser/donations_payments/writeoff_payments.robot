*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/SchedulePaymentPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
# Sets test data contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   contact_data=${contact1_fields}     opportunity_data=${opportunity_fields}    payment_data=${payment_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Auto Payment test $1000 Donation   Amount=1000     StageName=Pledged    npe01__Do_Not_Automatically_Create_Payment__c=true
&{payment_fields}        Amount=250   NumPayments=4   Interval=2

${No_of_payments}     4
${intervel}           2
${frequency}        Month

*** Test Cases ***
Verify values in Create one or more Payments for this Opportunity page
    [Documentation]                      Create four payment installations for the opportunity
    ...                                  Writeoff couple of payments

    Go To Page                           Details
    ...                                  Opportunity
    ...                                  object_id=${data}[contact_opportunity][Id]

    Select Tab                           Related
    Load Related List                    Payments
    Click First Matching Related Item Popup Link    Payments    Unpaid    Edit
    Wait Until Modal Is Open
    Set Checkbutton To                   Written Off             checked
    Click Button                         Save
    Wait Until Modal Is Closed
    Click Special Related List Button    Payments    Schedule Payments
    Current Page Should Be               Custom      SchedulePayment
    Verify Field Values
    ...                                  Payment Writeoff Amount=$250.00
    ...                                  Remaining Balance=$750.00
    Click Button                         Cancel
    Current Page Should Be               Details    Opportunity
    Select Tab                           Related
    Click First Matching Related Item Popup Link    Payments    Unpaid    Edit
    Wait Until Modal Is Open
    Set Checkbutton To                   Written Off    checked
    Set Checkbutton To                   Paid           checked
    Click Button                         Save
    Page Should Contain                  A Payment can't be both paid and written off. You must deselect one or both checkboxes.
    Click Button                         Cancel
    Current Page Should Be               Details         Opportunity
    Click ViewAll Related List           Payments
    Verify Details
        ...                              Unpaid=3
        ...                              Written Off=1


Verify values in Writeoff Remaining Balance Page
    [Documentation]                      Verify the remaining balance after the writeoffs are done

    Go To Page                          Details          Opportunity    object_id=${data}[contact_opportunity][Id]
    Select Tab                          Related
    Click First Matching Related Item Popup Link         Payments       Unpaid    Edit
    Wait Until Modal Is Open
    Set Checkbutton To                  Written Off      checked
    Populate Field                      Payment Amount   200
    Click Button                        Save
    Wait Until Modal Is Closed

    Navigate To Writeoff Payments Page
    Verify Field Values
    ...                                Payment Writeoff Amount=$450.00
    ...                                Remaining Balance=$550.00
    Page Should Contain                You are preparing to write off 2 Payment(s) totaling $550.00
    Choose Frame                       Write Off Remaining Balance
    Click Button                       Cancel
    Current Page Should Be             Details           Opportunity
    Select Tab                         Related
    Load Related List                  Payments
    Click ViewAll Related List         Payments
    Verify Details
    ...                                Unpaid=2
    ...                                Written Off=2