from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "npe03__Recurring_Donation__c")
class RDListingPage(BaseNPSPPage, ListingPage):
    object_name = "npe03__Recurring_Donation__c"


    
@pageobject("Details", "npe03__Recurring_Donation__c")
class RDDetailPage(BaseNPSPPage,DetailPage ):
    object_name = "npe03__Recurring_Donation__c"

    def _is_current_page(self):
        """ Verify we are on the Account detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Record view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/npe03__Recurring_Donation__c/",message="Current page is not a Recurring Donations record view")
    
    def refresh_opportunities(self):
        """Clicks on more actions dropdown and click the given title"""   
        locator=npsp_lex_locators['link-contains'].format("more actions")
        self.selenium.click_element(locator)
        self.selenium.wait_until_page_contains("Refresh Opportunities")
        link_locator=npsp_lex_locators['link'].format('Refresh_Opportunities','Refresh_Opportunities') 
       
    def click_actions_button(self,button_name):
        """Clicks on action button based on API version"""
        if self.npsp.latest_api_version == 47.0:
            self.selenium.click_link(button_name)
        else:
            self.selenium.click_button(button_name)    
             