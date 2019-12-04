from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators

@pageobject("Listing", "Account")
class AccountListingPage(ListingPage):
    object_name = "Account"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
@pageobject("Details", "Account")
class AccountDetailPage(DetailPage):
    object_name = "Account"

    def _is_current_page(self):
        """ Verify we are on the Account detail page
            by verifying that the url contains '/view'
        """
        self.npsp.wait_until_url_contains("/view")
    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')    