from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Details", "npe4__Relationship__c")
class RelationshipDetailPage(BaseNPSPPage, DetailPage):
    object_name = "npe4__Relationship__c"

    def _is_current_page(self):
        """ Verify we are on the Relationship detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view")
        self.selenium.location_should_contain("/lightning/r/npe4__Relationship__c/",message="Current page is not relationship detail view")
