from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from Basenpspobjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "Account")
class AccountListingPage(ListingPage, BaseNPSPPage):
    object_name = "Account"


    
@pageobject("Details", "Account")
class AccountDetailPage(DetailPage, BaseNPSPPage):
    object_name = "Account"

    def _is_current_page(self):
        """ Verify we are on the Account detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/Account/",message="Current page is not an Account record detail view")
    
 