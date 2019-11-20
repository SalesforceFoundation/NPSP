from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators

@pageobject("Listing", "Account")
class OpportunityPage(ListingPage):
    object_name = "Account"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    