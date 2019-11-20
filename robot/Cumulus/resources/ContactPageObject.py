from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators



@pageobject("Listing", "contact")
class ContactPage(ListingPage):
    object_name = "contact"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')


    def click_on_contacts(self, name):
        self.salesforce.go_to_object_home(object_name)
        self.salesforce.wait_until_loading_is_complete()


