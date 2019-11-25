from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators

@pageobject("Listing", "Account")
class OpportunityListingPage(ListingPage):
    object_name = "Account"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
@pageobject("Details", "Account")
class ContactDetailPage(DetailPage):
    object_name = "Account"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')    