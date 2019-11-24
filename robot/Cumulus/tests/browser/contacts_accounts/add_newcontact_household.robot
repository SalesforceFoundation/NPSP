*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Household With Different LastName

    &{contact1} =  API Create Contact       Email=skristem@robot.com
    Go To Record Home                       &{contact1}[AccountId]
    ${id}  Get Current Record Id
    Store Session Record                    Account    ${id}

    #Create a new contact under HouseHold Validation
    Click Related List Button               Contacts    New
    Wait Until Modal Is Open
    ${first_name} =                         Generate Random String
    ${last_name} =                          Generate Random String
    Populate Form
    ...                                     First Name=${first_name}
    ...                                     Last Name=${last_name}
    Click Modal Button                      Save
    Wait Until Modal Is Closed
    Go To Page                              Listing     Contact
    Click Link                              link= ${first_name} ${last_name}
    Wait Until Url Contains                 /view
    ${contact_id2} =                        Get Current Record Id
    Store Session Record                    Account  ${contact_id2}

    &{contact2} =                           Salesforce Get  Contact  ${contact_id2}
    Should Not Be Empty                     ${contact2}
    Header Field Value    Account Name      &{contact1}[LastName] and &{contact2}[LastName] Household
