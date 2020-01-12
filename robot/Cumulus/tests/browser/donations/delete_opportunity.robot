*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Sets up all the required data for the test based on the keyword requests
Setup Test Data
    &{Data} =  Setup Data
               ...           contact1=&{contact1_fields}
               ...           opportunity for contact1=&{opportunity_fields}

    Set suite variable    &{Data}

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Delete test $100 Donation   Amount=100  StageName=Closed Won


Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact and Delete Opportunity
    [Documentation]                      Create an opportunity using API for a contact. Navigate to Opportunities listings, select the
    ...                                  new opportunity > click on dropdown and select Delete

    [tags]                               W-038461                 feature:Donations

    Go To Page                           Detail
    ...                                  Opportunity
    ...                                  object_id=&{data}[contact1opportunityid]

    ${donation_name}                     Get Main Header
    Go To Page                           Listing
    ...                                  Opportunity

    Select Row                           ${donation_name}
    Click Link                           link=Delete
    Click Modal Button                   Delete
    Page Contains Record                 ${donation_name}

    Go To Page                           Details
    ...                                  Contact
    ...                                  object_id=&{data}[contact1_AccountId]

    Select Tab                           Details

    # Validations
    Validate Field Value Under Section   Membership Information    Total Gifts                 $0.00
    Validate Field Value Under Section   Membership Information    Total Number of Gifts       0

