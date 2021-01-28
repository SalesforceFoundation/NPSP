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
        [Documentation]         Create a contact and recurring donation record of type open using API
        ...                     Associate the recurring donation to the contact

        ${NS} =             Get NPSP Namespace Prefix
        Set Suite Variable  ${NS}

        #Create a Recurring Donation
        &{contact1_fields}=   Create Dictionary                     Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERD Open Recurring Donation
        ...                                                         npe03__Installment_Period__c=Yearly
        ...                                                         npe03__Amount__c=100
        ...                                                         npe03__Open_Ended_Status__c=Open
        ...                                                         npe03__Date_Established__c=2019-07-08
        ...                                                         ${NS}Status__c=Active
        ...                                                         ${NS}Day_of_Month__c=15
        ...                                                         ${NS}InstallmentFrequency__c=1
        ...                                                         ${NS}PaymentMethod__c=Check

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}


*** Test Cases ***

Edit An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test ensures that the user
     ...                          is able to invoke the pause modal by clicking on the pause button.
     ...                          User can fill the paused reason and check the date to pause
     ...                          Validates the Pasued text next to the paused installment date and current and next
     ...                          Year values


    [tags]                                                      W-8116680          feature:RD2

    Go To Page                                    Listing                                   npe03__Recurring_Donation__c

    Reload Page
    Click Link                                    New
    Wait For Rd2 Modal
    Go To Page                                    Details
    ...                                           npe03__Recurring_Donation__c
    ...                                           object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    Current Page Should be                        Details                                  npe03__Recurring_Donation__c

    #Get the next payment installment date and pause the recurring donation for the next payment date
    ${date}                                       Get Next Payment Date Number        1     False
    ${PAUSE_DATES}=                               Create List           ${date}
    Pause Recurring Donation
    # Verify user is able to enter the paused reason and check the date and hit submit button
    Populate Pause Modal
    ...	                                          Paused Reason=Card Expired
    ...	                                          Date=@{PAUSE_DATES}

    # Verify Paused text appears next to the date specified
    Verify Pause Text Next To Installment Date	  @{PAUSE_DATES}
    Run Recurring Donations Batch                 RD2
    # Verify the calculations for current and next year payments
    Go To Page                                    Details
    ...                                           npe03__Recurring_Donation__c
    ...                                           object_id=${data}[contact_rd][Id]
    Validate Current And Next Year values         100
