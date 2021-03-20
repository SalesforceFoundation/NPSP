*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
        [Documentation]         Create a contact and recurring donation record of type open using API
        ...                     Associate the recurring donation to the contact

        ${NS} =                 Get NPSP Namespace Prefix
        Set Suite Variable      ${NS}

        #Create a Recurring Donation
        &{contact1_fields}=             Create Dictionary           Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERD Open Recurring Donation
        ...                                                         npe03__Installment_Period__c=Monthly
        ...                                                         npe03__Amount__c=${AMOUNT}
        ...                                                         npe03__Open_Ended_Status__c=${TYPE}
        ...                                                         npe03__Date_Established__c=2020-01-01
        ...                                                         ${NS}StartDate__c=2020-01-01
        ...                                                         ${NS}Status__c=Active
        ...                                                         ${NS}Day_of_Month__c=${DAY_OF_MONTH}
        ...                                                         ${NS}InstallmentFrequency__c=${FREQUENCY}
        ...                                                         ${NS}PaymentMethod__c=Check

        Setupdata   contact            ${contact1_fields}           recurringdonation_data=${recurringdonation_fields}

*** Variables ***
${FREQUENCY}  1
${DAY_OF_MONTH}  5
${AMOUNT}  10
${METHOD}  Check
${TYPE}    Open


*** Test Cases ***

Edit An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test ensures that after
    ...                           A pause action is made on the RD and the night job is run, then the
    ...                           Status of the RD changes to Paused from Active and When the user decides to
    ...                           Unpause the paused installment then the status on the RD changes back to Active

    [tags]                                                   W-8237882          feature:RD2         unstable

    Go To Page                                Listing                                   npe03__Recurring_Donation__c

    Reload Page
    Click Link                                New
    Wait For Rd2 Modal
    Go To Page                                Details
    ...                                       npe03__Recurring_Donation__c
    ...                                       object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    Current Page Should be                    Details                                  npe03__Recurring_Donation__c

    # Get the first installment payment dates to pause
    ${date1}                                  Get Next Payment Date Number        1     False
    ${PAUSE_DATES_EDITED}=                    Create List           ${date1}
    Pause Recurring Donation

    # Verify user is able to click on the pause modal and update with new pause dates
    # Run the nightly batch job
    Populate Pause Modal
    ...	                                      Paused Reason=Card Expired
    ...	                                      Date=@{PAUSE_DATES_EDITED}
    ...                                       Validate=selected 1 installment

    Run Recurring Donations Batch             RD2

    Go To Page                                Details
    ...                                       npe03__Recurring_Donation__c
    ...                                       object_id=${data}[contact_rd][Id]

    Navigate To And Validate Field Value      Status           contains       Paused          Other Information
    Pause Recurring Donation
    # Verify user is able to click on the pause modal and update with new pause dates
    Populate Pause Modal
    ...	                                      Date=@{PAUSE_DATES_EDITED}

    Run Recurring Donations Batch             RD2
    Go To Page                                Details
    ...                                       npe03__Recurring_Donation__c
    ...                                       object_id=${data}[contact_rd][Id]

    Navigate To And Validate Field Value      Status           contains       Active          Other Information