from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "ManageHousehold")
class ManageHouseholdPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("DataImport__c",message="Current page is not a DataImport List view")


    def _go_to_page(self, filter_name=None):

        """
        Verifies that current page is Manage Household
        """
        self.selenium.wait_until_location_contains("/one",timeout=60, message="Records list view did not load in 1 min")
        self.npsp.wait_for_locator("frame","Manage Household")
        #self.npsp.choose_frame("Manage Household")
        #self.npsp.select_frame_and_click_element("Manage Household", "span_button", "change Address")

    def change_address_using(self, option, **kwargs):
        """
         Changes address setting based on the type of options chosen
         provided options (Select An Existing Address/Enter A new Address)
        """
        if option == "Enter a new address":
           self.npsp.click_managehh_link("Enter a new address")
           self.npsp.populate_modal_form(**kwargs)
           self.npsp.click_span_button("Set Address")
           self.selenium.click_button("Save")
        self.selenium.unselect_frame()

    def add_contact(self, option, value):
        """
         Performs a lookup of the contact provided as parameter and adds the contact to the hold based on the option
         provided options (New/Existing)
        """
        self.npsp.choose_frame("Manage Household")
        self.npsp.search_field_by_value("Find a Contact or add a new Contact to the Household", value)
        lookup_ele=npsp_lex_locators['household_lookup_dropdown_menu']
        self.selenium.wait_until_element_is_visible(lookup_ele)

        if option == "Existing":
            self.selenium.click_button("Add")

        if option == "New":
            self.selenium.click_button("New Contact")
            self.npsp.wait_for_locator("span_button", "New Contact")
            self.npsp.click_span_button("New Contact")

        self.selenium.wait_until_element_is_not_visible(lookup_ele)
        self.selenium.click_button("Save")
        self.selenium.unselect_frame()

    def validate_and_select_checkbox(self,contact,option):
        """
         Select the option for name display settings for each of the contact in the household
         provided options (Household Name/ Formal Greeting/Informal Greeting)
        """
        self.npsp.choose_frame("Manage Household")
        loc=self.npsp.validate_checkbox(contact,option)
        self.selenium.double_click_element(loc)
        self.selenium.unselect_frame()

    def save_changes_made_for_manage_household(self):
        self.npsp.choose_frame("Manage Household")
        self.selenium.click_button("Save")
        self.selenium.unselect_frame()


