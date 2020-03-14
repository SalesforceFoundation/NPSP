from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.pageobjects import BasePage
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Custom", "Lead")
class CovertLeadPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the Leads iframe to load
        """
        self.npsp.wait_for_locator('frame_new','vfFrameId','vfFrameId')
        self.npsp.choose_frame('vfFrameId')

    def click_lead_convert_button(self):
        self.npsp.page_scroll_to_locator('button', 'Convert')
        self.selenium.click_button('Convert')


@pageobject("Listing", "Lead")
class LeadListingPage(BaseNPSPPage, ListingPage):
    object_name = "Lead"


@pageobject("Details", "Lead")
class LeadDetailPage(BaseNPSPPage, DetailPage):
    object_name = "Lead"
    def _is_current_page(self):
        """ Verify we are on the Lead detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail page did not load in 1 min")
        self.selenium.location_should_contain("/lightning/r/Lead/",message="Current page is not a Lead record detail view")