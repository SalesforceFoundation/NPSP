from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Detail", "EngagementTemplate")
class EngagementTemplatePage(BaseNPSPPage, DetailPage):
    object_name = "npsp__Engagement_Plan_Template__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Template view details page
            by verifying that the url contains '/view'
        """

        self.selenium.wait_until_location_contains("/lightning/r/npsp__Engagement_Plan_Template__c", timeout=60, message="Engagement Template detail view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/npsp__Engagement_Plan_Template__c",message="Current page is not a Engagement Template detail view")


@pageobject("Listing", "EngagementTemplate")
class EngagementTemplatePage(BaseNPSPPage, ListingPage):
    object_name = "npsp__Engagement_Plan_Template__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Templates Lists page
            by verifying that the url contains '/list'

        """
        self.selenium.wait_until_location_contains("/lightning/o/npsp__Engagement_Plan_Template__c/list", timeout=60, message="Engagement Template list view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/o/npsp__Engagement_Plan_Template__c/list",message="Current page is not Engagement Template Listings")
