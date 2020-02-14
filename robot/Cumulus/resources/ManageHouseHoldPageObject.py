from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from cumulusci.robotframework.utils import capture_screenshot_on_error
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "ManageHousehold")
class ManageHouseholdPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Manage Household page
        """
        self.selenium.wait_until_location_contains("/one",timeout=60, message="Manage Household page did not load in 1 min")


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
           self.npsp.click_managehh_link("Enter a new address")
           self.npsp.populate_modal_form(**kwargs)
           self.npsp.click_span_button("Set Address")
           self.selenium.click_button("Save")
        self.selenium.unselect_frame()

    @capture_screenshot_on_error
    def add_contact(self, option, value):
        """
         Performs a lookup of the contact provided as parameter and adds the contact to the hold based on the option
         Supported options are (New/Existing)
        """
        self.npsp.choose_frame("Manage Household")
        self.npsp.search_field_by_value("Find a Contact or add a new Contact to the Household", value)
        lookup_ele=npsp_lex_locators['household_lookup_dropdown_menu']
        self.selenium.wait_until_element_is_visible(lookup_ele)

        if option.lower() == "existing":
            self.selenium.click_button("Add")

        elif option.lower() == "new":
            self.selenium.click_button("New Contact")
            self.npsp.wait_for_locator("span_button", "New Contact")
            self.npsp.click_span_button("New Contact")
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


