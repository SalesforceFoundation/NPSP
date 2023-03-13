*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
        [Documentation]     Creates a recurring donation of type open linked to a contact using backend API
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
        ...                                                         ${NS}Day_of_Month__c=20
        ...                                                         ${NS}InstallmentFrequency__c=1
        ...                                                         ${NS}PaymentMethod__c=Check

        Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}


*** Test Cases ***

Edit Day Of Month For Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API, An edit action is performed
     ...                          To update the day of month field . A validation is then performed to ensure that the
     ...                          Edit did not result in duplicate opportunities getting created. Assert is made to
     ...                          Ensure there is only one Opportunity


    [tags]                                  feature:RD2     api

    Go To Page                              Listing                                   npe03__Recurring_Donation__c
    Current Page Should Be                  Listing                                   npe03__Recurring_Donation__c
    Click Link                              New
    Wait For Rd2 Modal

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    #Update only Day Of Month Field on the edit modal
    Current Page Should be                  Details    npe03__Recurring_Donation__c
    Edit Recurring Donation Status
        ...                                 Recurring Period=Monthly
        ...                                 Day of Month=1

    Go To Page                              Details
        ...                                 npe03__Recurring_Donation__c
        ...                                 object_id=${data}[contact_rd][Id]
    Current Page Should be                  Details    npe03__Recurring_Donation__c
    #Validate the number of opportunities on UI, Verify Opportinity got created in the backend
    Validate Related Record Count           Opportunities                                                    1
    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${data}[contact_rd][Id]
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]

    #validate the stage on opportunity
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Current Page Should be                  Details                        Opportunity
    Wait Until Loading Is Complete
    Navigate To And Validate Field Value    Stage                          contains                        Pledged