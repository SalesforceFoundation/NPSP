from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "SchedulePayment")
class SchedulePaymentPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the Schedule Payments iframe to load in the edit mode
        """
        self.npsp.wait_for_locator('frame','Create one or more Payments for this Opportunity')
        self.npsp.choose_frame('Create one or more Payments for this Opportunity')

    def enter_textfield_value(self, inputvalue):
        locator = self.npsp.get_npsp_locator('id', 'inputX')
        self.salesforce._populate_field(locator, inputvalue)

