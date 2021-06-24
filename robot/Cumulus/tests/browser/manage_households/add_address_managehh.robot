*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/ManageHouseHoldPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    &{contact1} =           API Create Contact
    ...                     MailingStreet=50 Fremont Street
    ...                     MailingCity=San Francisco
    ...                     MailingPostalCode=95320
    ...                     MailingState=CA
    ...                     MailingCountry=USA

    Store Session Record  Account                               ${contact1}[AccountId]
    Set suite variable    &{contact1}

*** Variables ***
&{Address}       street=123 Dummy Street    city=Tracy, CA 99999        country=US

*** Test Cases ***

Add New Address to Household
    [Documentation]                      Create a contact providing the address details using the backend API
    ...                                  Navigate to the contact's Account details page and update the address
    ...                                  To a new value from the manage housold page.
    ...                                  Navigate to contact details and account details page.
    ...                                  Verify the new address persists under both Mailing and Billing address details
    ...                                  Verify Same address should be present on Account and Contacts

    [tags]                               unstable             W-038348             feature: Manage Households           notonfeaturebranch

    Go To Page                           Details
    ...                                  Account
    ...                                  object_id=${contact1}[AccountId]

    Click Button                         Manage Household
    Current Page Should Be               Custom                             ManageHousehold
    Select Frame And Click Element       Manage Household
    ...                                  span_button
    ...                                  Change Address
    Change Address Using                 Enter a new address               Street=123 Dummy Street
    ...                                                                    City=Tracy
    ...                                                                    State=CA
    ...                                                                    Postal Code=99999
    ...                                                                    Country=US

    Go To Page                          Details
    ...                                 Contact
    ...                                 object_id=${contact1}[Id]

    cumulusci.robotframework.Salesforce.Scroll Element Into View            text:Mailing Address
    Verify Address Details              Mailing Address
    ...                                 contains
    ...                                 &{Address}

    Go To Page                          Listing                             Account
    Click Link                          link=${contact1}[LastName] Household
    Select Tab                          Details
    cumulusci.robotframework.Salesforce.Scroll Element Into View            text:Billing Address

    verify address details              Billing Address
    ...                                 contains
    ...                                 &{Address}
