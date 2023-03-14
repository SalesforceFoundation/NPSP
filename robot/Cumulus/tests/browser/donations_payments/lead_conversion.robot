*** Settings ***
Library  String
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/LeadsPageObject.py

Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Convert Lead To Account
    [tags]                    feature:Donations and Payments   unstable  api
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    ${company} =              Generate Random String
    Go To Page                       Listing                 Lead
    Click Object Button              New
    Populate Modal Form
    ...                              First Name=${first_name}
    ...                              Last Name=${last_name}
    ...                              Company=${company}
    ...                              Street=50 Fremont Street
    ...                              City=San Francisco
    ...                              Zip/Postal Code=95320
    ...                              State/Province=CA
    ...                              Country=USA
    Select Value From Dropdown       Lead Status              Working - Contacted
    Click Modal Button               Save
    Wait Until Modal Is Closed
    Go To Page                       Listing                 Lead
    Click Link                       link=${first_name} ${last_name}
    Wait And Click Button                     title:Convert
    Current Page Should Be           Custom                  Lead
    Click lead convert button
    Go To Page                       Listing                 Contact
    Page Should Contain Link         ${first_name} ${last_name}
    Go To Page                       Listing                 Account
    Page Should Contain Link         ${last_name} Household
    Page Should Contain Link         ${company}

