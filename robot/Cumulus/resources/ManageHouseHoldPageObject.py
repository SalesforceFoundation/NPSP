import time
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from cumulusci.robotframework.utils import capture_screenshot_on_error
from selenium.webdriver.common.keys import Keys
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "ManageHousehold")
class ManageHouseholdPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Manage Household page
        """
        self.selenium.wait_until_location_contains("/one",timeout=60, message="Manage Household page did not load in 1 min")
        self.npsp.wait_for_locator("frame","Manage Household")


    def _go_to_page(self, filter_name=None):

        """
        Verifies that current page is Manage Household
        """
        self.selenium.wait_until_location_contains("/one",timeout=60, message="Manage Household page did not load in 1 min")
        self.npsp.wait_for_locator("frame","Manage Household")

    def change_address_using(self, option, **kwargs):
        """
         Changes address setting based on the type of options chosen
         Supported option is (Enter A new Address)
        """
        if option.lower() == "enter a new address":
           locator=npsp_lex_locators['button-title'].format("Enter a new address")
           self.selenium.click_button(locator)
           self.npsp.populate_modal_form(**kwargs)
           self.selenium.click_button("Set Address")
           self.selenium.click_button("Save")
        self.selenium.unselect_frame()

    @capture_screenshot_on_error
    def add_contact(self, option, value):
        """
         Performs a lookup of the contact provided as parameter and adds the contact to the hold based on the option
         Supported options are (New/Existing)
        """
        self.npsp.choose_frame("Manage Household")
        xpath = npsp_lex_locators['manage_hh_page']['lookup'].format("Find a Contact or add a new Contact to the Household.")
        field = self.selenium.get_webelement(xpath)
        self.selenium.clear_element_text(field)
        field.send_keys(value)
        time.sleep(3)
        field.send_keys(Keys.ENTER)
        lookup_ele=npsp_lex_locators['household_lookup_dropdown_menu']
        self.selenium.wait_until_element_is_visible(lookup_ele)

        if option.lower() in ("new", "existing"):
            new_contact_locator=npsp_lex_locators['manage_hh_page']['add_contact_option'].format("New Contact")
            new_contact_btn=npsp_lex_locators['button-title'].format("New Contact")
            self.selenium.wait_until_element_is_visible(new_contact_locator)
            self.selenium.click_element(new_contact_locator)
            self.selenium.wait_until_element_is_visible(new_contact_btn)
            self.selenium.click_button(new_contact_btn)
        else:
            print("Invalid option")

        self.selenium.wait_until_element_is_not_visible(lookup_ele)
        self.selenium.click_button("Save")
        self.selenium.unselect_frame()

    def validate_and_select_checkbox(self,contact,option):
        """
         Select the option for name display settings for each of the contact in the household
         provided options (Household Name/ Formal Greeting/Informal Greeting)
        """
        self.npsp.choose_frame("Manage Household")
        loc=self.npsp.validate_checkboxes(contact,option)
        self.selenium.double_click_element(loc)
        self.selenium.unselect_frame()

    def save_changes_made_for_manage_household(self):
        self.npsp.choose_frame("Manage Household")
        self.selenium.click_button("Save")
        self.selenium.unselect_frame()


