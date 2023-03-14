*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

*** Test Cases ***

Check Recurring Donation Autoname
    [Documentation]              This test verifies that the Autonaming setting for Recurring Donations is working properly.
    ...                          When the autonaming setting is enabled , After a recurring donation is created, verify that
    ...                          Recurring donation has Autonaming
    [tags]                       feature:Recurring Donations     unit

    #Enable Autonaming Setting
    @{recurringsettings} =       Salesforce Query                             npe03__Recurring_Donations_Settings__c
    ...                          select=Id,${ns}EnableAutomaticNaming__c
    Salesforce Update            npe03__Recurring_Donations_Settings__c       ${recurringsettings}[0][Id]
    ...                          ${ns}EnableAutomaticNaming__c=true

    #Create a contact and a recurring donation for the contact
    &{contact1_fields}=          Create Dictionary                           Email=test@example.com
    &{recurringdonation_fields} =	Create Dictionary                        Name=Name Should Overwrite
            ...                                                              npe03__Installment_Period__c=Monthly
            ...                                                              npe03__Amount__c=1200
            ...                                                              npe03__Installments__c=12
            ...                                                              npe03__Schedule_Type__c=Divide By

    Setupdata   contact         ${contact1_fields}                          recurringdonation_data=${recurringdonation_fields}

    #Navigate to the recurring donation page
    Go To Page                   Details        npe03__Recurring_Donation__c   object_id=${data}[contact_rd][Id]

    #Check Recurring Donation Autoname
    Navigate To And Validate Field Value        Recurring Donation Name        contains           ${data}[contact][Name] $1,200 - Recurring

    #Turn off Autonaming to Reset Setting
    Salesforce Update            npe03__Recurring_Donations_Settings__c       ${recurringsettings}[0][Id]
    ...                          ${ns}EnableAutomaticNaming__c=false