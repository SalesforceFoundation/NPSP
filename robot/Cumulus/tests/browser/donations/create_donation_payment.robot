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
    Setupdata   contact   ${contact1_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com


*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    [Documentation]  Navigate to Opportunities page and open an Opportunity>In the right sections, go to Payments click on drop down Arrow>New
    ...              Create a new payment for the Opportunity.

    [tags]                                          W-038461                 feature:Donations

    Go To Page                                      Listing
    ...                                             Opportunity

    Click Object Button                             New
    Select Record Type                              Donation

    Create Opportunities                            Sravani $100 donation
    ...                                             ${data}[contact][LastName] Household
    ...                                             Closed Won

    Save Current Record ID For Deletion             Opportunity
    Current Page Should Be                          Detail                                  Opportunity

    Verify Payments Made                            0

    #Make A New Payment

    Click Related List Button                       Payments                                New
    Wait For Modal                                  New                                     Payment
    Select Window
    Populate Modal Form                             Payment Amount=100
    ...                                             Payment Method=Credit Card

    Open Date Picker                                Payment Date
    Pick Date                                       Today
    Click Modal Button                              Save

    Verify Payments Made                            1

    Go To Page                                      Details
    ...                                             Contact
    ...                                             object_id=${data}[contact][Id]

    #Perform Validations
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Validate Field Value Under Section   Donation Totals      Last Gift Date                  ${opp_date}
    Validate Field Value Under Section   Soft Credit Total    Total Gifts                     $100.00
    Validate Field Value Under Section   Soft Credit Total    Total Number of Gifts           1
