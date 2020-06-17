from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "Account")
class AccountListingPage(BaseNPSPPage, ListingPage):
    object_name = "Account"


    
@pageobject("Details", "Account")
class AccountDetailPage(BaseNPSPPage,DetailPage ):
    object_name = "Account"

    def _is_current_page(self):
        """ Verify we are on the Account detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains(f"/lightning/r/Account/",timeout=60,
                                                   message="Current page is not an Account record detail view")
    
    def validate_rollup_field_contains(self,field, *args):
        """ verifies if the text value of the field matches the accepted values passed as a list
        """
        locator = npsp_lex_locators["confirm"]["check_text_value"].format(field)
        if self.npsp.check_if_element_exists(locator):
            print(f"element exists {locator}")
            actual_value=self.selenium.get_webelement(locator).text
            if actual_value in str(args):
                print(f"rollup field values is in the accepted values")
            else:
                raise Exception(f"values for the field This Year Payments on Past Year Pledges do not exist in accepted rollup values")
        