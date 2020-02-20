*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

*** Test Cases ***

Check Recurring Donation Autoname
    [Documentation]              This test verifies that the Autonaming setting for Recurring Donations is working properly.

    #Enable Autonaming Setting
    @{recurringsettings} =       Salesforce Query                           npe03__Recurring_Donations_Settings__c
    ...                          select=Id,${ns}EnableAutomaticNaming__c
    Salesforce Update            npe03__Recurring_Donations_Settings__c     ${recurringsettings}[0][Id]
    ...                          ${ns}EnableAutomaticNaming__c=true

    #Create a Recurring Donation
    &{contact} =                 API Create Contact                         Email=jjoseph@robot.com
    Go To Page                   Details        Contact             object_id=&{contact}[Id]
    &{recurringdonation} =       API Create Recurring Donation              npe03__Contact__c=&{contact}[Id]
    ...                          Name=Name Should Overwrite
    ...                          npe03__Amount__c=1200
    ...                          npe03__Installments__c=12
    ...                          npe03__Schedule_Type__c=Divide By
    ...                          npe03__Installment_Period__c=Monthly
    Go To Page                   Details        npe03__Recurring_Donation__c             object_id=&{recurringdonation}[Id]

    #Check Recurring Donation Autoname
    Navigate To And Validate Field Value          Recurring Donation Name          contains           &{contact}[Name] $1,200 - Recurring

    #Turn off Autonaming to Reset Setting
    Salesforce Update            npe03__Recurring_Donations_Settings__c     ${recurringsettings}[0][Id]
    ...                          ${ns}EnableAutomaticNaming__c=false