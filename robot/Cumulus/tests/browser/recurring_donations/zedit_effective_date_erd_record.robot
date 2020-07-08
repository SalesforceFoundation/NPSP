*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             DateTime
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable RD2
#Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Setup Test Data

        ${effective_date_initial} =           Get Current Date      result_format=%-m/%-d/%Y
        ${date} =           Get Current Date
        ${DATE}=            Add Time To Date      ${date}  30 days      result_format=%Y-%m-%d %H:%M:%S.%f
        ${date_to_update} =   Convert Date                   ${DATE}                         result_format=%Y-%m-%d
        ${effective_modified_date}=        Add Time To Date      ${date}  0 days     result_format=%-m/%-d/%Y
        ${currdate}=        Get Current Date  result_format=datetime
        ${currentvalue} =   Evaluate          (${currdate.month-1}) * 100
        ${currentvalue_edited}=   Evaluate    (${currdate.month}*100) + 150
        Set Suite Variable  ${currentvalue}
        Set Suite Variable  ${DATE}
        Set Suite Variable  ${effective_modified_date}
        Set Suite Variable  ${currentvalue_edited}
        Set Suite Variable  ${effective_date_initial}
        Set Suite Variable  ${date_to_update}

        &{contact1_fields}=   Create Dictionary                     Email=rd2tester@example.com
        &{recurringdonation_fields} =	Create Dictionary           Name=ERDTest1
        ...                                                         npe03__Installment_Period__c=Monthly
        ...                                                         npe03__Amount__c=100
        ...                                                         npe03__Open_Ended_Status__c=${type}
        ...                                                         Status__c=Active
        ...                                                         Day_of_Month__c=15
        ...                                                         InstallmentFrequency__c=${frequency}
        ...                                                         PaymentMethod__c=${method}

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}


*** Variables ***
${frequency}  1
${day_of_month}  15
${amount_to_update}  150
${method}  Credit Card
${type}    Open

*** Test Cases ***

Edit An Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, The test ensures that when the record
     ...                          is edited and effective date is updated to next month , Verifies that future schedule is shown
     ...                          with the right values reflected. Verifies the current year and future year schedules are updated
     ...                          Verifies the opportunity status


    [tags]                                   unstable               W-041167            feature:RD2

    Go To Page                               Details
    ...                                      npe03__Recurring_Donation__c
    ...                                      object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete

    ${rd_id}                                 Save Current Record ID For Deletion       npe03__Recurring_Donation__c

    Validate Field Values Under Section

    ...                                      Amount=$100.00
    ...                                      Status=Active

    # Validate the fields under Current Schedule card
    Validate Field Values Under Section      Current Schedule
    ...                                      Amount=$100.00
    ...                                      Payment Method=Credit Card
    ...                                      Effective Date=${effective_date_initial}
    ...                                      Installment Period=Monthly
    ...                                      Day of Month=15

    # validate recurring donation statistics current and next year value
    Validate Field Values Under Section      Statistics
    ...                                      Current Year Value=$${currentvalue}.00
    ...                                      Next Year Value=$1,200.00

    #Query the opportunity ID associated with the recurring donation. Navigate to the opportunity and validate the status
    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${rd_id}
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value    Stage                          contains                        Pledged

    #Using backend API update the recurring donation record and modify the startDate field to next month's date
    API Modify Recurring Donation           ${data}[contact_rd][Id]
    ...                                     npe03__Amount__c=${amount_to_update}
    ...                                     StartDate__c=${date_to_update}

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete

    # Verify that Future schedule section shows up and the values reflect the changes
    Validate Field Values Under Section     Future Schedule
    ...                                     Amount=$150.00
    ...                                     Payment Method=Credit Card
    ...                                     Effective Date=${effective_modified_date}
    ...                                     Installment Period=Monthly
    ...                                     Day of Month=15

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]

    Wait Until Loading Is Complete
    Validate Field Values Under Section     Statistics
    ...                                     Current Year Value=$${currentvalue_edited}.00
    ...                                     Next Year Value=$1,800.00

    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${rd_id}
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value    Stage                          contains                        Pledged