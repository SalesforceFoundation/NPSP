from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "npe5__Affiliation__c")
class AffiliationListingPage(BaseNPSPPage, ListingPage):
    object_name = "npe5__Affiliation__c"


    
@pageobject("Details", "npe5__Affiliation__c")
class AffiliationDetailPage(BaseNPSPPage,DetailPage ):
    object_name = "npe5__Affiliation__c"

    def _is_current_page(self):
        """ Verify we are on the Account detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Record view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/npe5__Affiliation__c/",message="Current page is not an Affiliation record view")
    
 