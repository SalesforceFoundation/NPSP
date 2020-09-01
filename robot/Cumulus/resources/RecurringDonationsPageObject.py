from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from datetime import datetime
from dateutil.relativedelta import relativedelta


@pageobject("Listing", "npe03__Recurring_Donation__c")
class RDListingPage(BaseNPSPPage, ListingPage):
    object_name = "npe03__Recurring_Donation__c"

    @capture_screenshot_on_error
    def click_rd2_modal_button(self, name):
        """Based on the button name (Cancel)  or (Save) on the modal footer, selects and clicks on the respective button"""
        btnlocator = npsp_lex_locators["button-with-text"].format(name)
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.click_element(btnlocator)

    @capture_screenshot_on_error
    def select_value_from_rd2_modal_dropdown(self, dropdown, value):
        """Selects given value from the dropdown field on the rd2 modal"""
        locator = npsp_lex_locators["erd"]["modal_dropdown_selector"].format(dropdown)
        selection_value = npsp_lex_locators["erd"]["modal_selection_value"].format(value)
        if self.npsp.check_if_element_exists(locator):
            self.selenium.set_focus_to_element(locator)
            self.selenium.wait_until_element_is_visible(locator)
            self.selenium.scroll_element_into_view(locator)
            self.salesforce._jsclick(locator)
            self.selenium.wait_until_element_is_visible(selection_value)
            self.selenium.click_element(selection_value)
        else:
            self.builtin.log(f"dropdown element {dropdown} not present")

    @capture_screenshot_on_error
    def populate_rd2_modal_form(self, **kwargs):
        """Populates the RD2 modal form fields with the respective fields and values"""
        ns=self.npsp.get_npsp_namespace_prefix()
        for key, value in kwargs.items():
            locator = npsp_lex_locators["erd"]["modal_input_field"].format(key)
            # Recurring Donation Name field only appears on a regression org hence this check
            if key == "Recurring Donation Name" and ns=="npsp__":
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.salesforce._populate_field(locator, value)
                else:
                    self.builtin.log(f"Element {key} not found")
            if key in ("Amount", "Number of Planned Installments"):
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.salesforce._populate_field(locator, value)
                else:
                    self.builtin.log(f"Element {key} not found")
            if key in ("Account", "Contact"):
                self.salesforce.populate_lookup_field(key, value)
            else:
                self.select_value_from_rd2_modal_dropdown(key, value)


@pageobject("Details", "npe03__Recurring_Donation__c")
class RDDetailPage(BaseNPSPPage, DetailPage):
    object_name = "npe03__Recurring_Donation__c"

    def _is_current_page(self):
        """ Verify we are on the Recurring Donations Detail page
            by verifying that the url contains '/view'
        """
        for i in range(3):
            self.selenium.location_should_contain(
                "/lightning/r/npe03__Recurring_Donation__c/",
                message="Current page is not a Recurring Donations record view",
            )
            locator = npsp_lex_locators["bge"]["button"].format("Edit")
            edit_button = self.selenium.get_webelement(locator)
            self.selenium.wait_until_page_contains_element(edit_button, error="Recurring donations Details page did not load fully")
            if self.npsp.check_if_element_displayed(edit_button):
                return
            else:
                self.selenium.reload_page()
                i += 1

    def refresh_opportunities(self):
        """Clicks on more actions dropdown and click the given title"""
        locator = npsp_lex_locators["link-contains"].format("more actions")
        self.selenium.click_element(locator)
        self.selenium.wait_until_page_contains("Refresh Opportunities")

    def click_actions_button(self, button_name):
        """Clicks on action button based on API version"""
        if self.npsp.latest_api_version == 47.0:
            self.selenium.click_link(button_name)
        else:
            self.selenium.click_button(button_name)
            
            
    def go_to_recurring_donation_related_opportunities_page(self,rd_id):

        """ Navigates to the related opportunities page of the given recurring donation ID """
        objectname = "npe03__Donations__r"
        values =  self.npsp.get_url_formatted_object_name(objectname)
        url = "{}/lightning/r/{}/related/{}/view".format(values['baseurl'],rd_id,objectname)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        locator = npsp_lex_locators["link-title"].format("New")
        new_button = self.selenium.get_webelement(locator)
        self.selenium.wait_until_page_contains_element(new_button, error="Recurring Donations related opportunities page did not load fully")
    
    @capture_screenshot_on_error
    def edit_recurring_donation_status(self, **kwargs):
        """From the actions dropdown select edit action and edit the fields specified in the kwargs
           |  Example
           |     Edit Recurring Donation Status
           |     ...                        Recurring Period=Advanced
           |     ...                        Every=3
        """
        locator = npsp_lex_locators["bge"]["button"].format("Edit")
        edit_button = self.selenium.get_webelement(locator)
        self.selenium.wait_until_element_is_visible(edit_button)
        self.selenium.click_element(locator)
        self.salesforce.wait_until_modal_is_open()
        self._populate_edit_status_values(**kwargs)
        btnlocator = npsp_lex_locators["button-with-text"].format("Save")
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.click_element(btnlocator)
        self.salesforce.wait_until_modal_is_closed()

    @capture_screenshot_on_error
    def _populate_edit_status_values(self, **kwargs):
        """Takes the key value pairs to edit and makes changes accordingly"""
        for key, value in kwargs.items():
            if key in ("Amount", "Number of Planned Installments", "Every"):
                locator = npsp_lex_locators["erd"]["modal_input_field"].format(key)
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.salesforce._populate_field(locator, value)
                else:
                    self.builtin.log(f"Element {key} not present")
            else:
                locator = npsp_lex_locators["erd"]["modal_dropdown_selector"].format(key)
                selection_value = npsp_lex_locators["erd"]["modal_selection_value"].format(value)
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.selenium.wait_until_element_is_visible(locator)
                    self.selenium.scroll_element_into_view(locator)
                    self.salesforce._jsclick(locator)
                    self.selenium.wait_until_element_is_visible(selection_value)
                    self.selenium.click_element(selection_value)
                else:
                    self.builtin.log(f"Element {key} not present")

    @capture_screenshot_on_error
    def verify_schedule_warning_messages_present(self):
        """Verify that the schedule warning messages are present when there are no schedules"""
        message_locator = npsp_lex_locators["erd"]["text_message"]
        list_ele = self.selenium.get_webelements(message_locator)
        p_count = len(list_ele)
        if p_count == 2:
            return
        else:
            raise Exception("Schedule warning messages do not exist")

    @capture_screenshot_on_error
    def validate_field_values_under_section(self, section=None, **kwargs):
        """Based on the section name , navigates to the sections and validates the key. value pair values passed in kwargs.
         If the section is current schedule, waits for the Current schedule section card on the side bar
         Validates the display fields in the card match with the values passed in the key value pair"""

        if section == "Current Schedule":
            active_schedule_card = npsp_lex_locators["erd"]["active_schedules_card"].format(section)
            number_fields = ["Amount", "Installment Frequency"]
            date_fields = ["Effective Date"]
            self.selenium.wait_until_element_is_visible(active_schedule_card, 60)
            for label, value in kwargs.items():
                if label in number_fields:
                    locator = npsp_lex_locators["erd"]["formatted_number"].format(label)
                    actual_value = self.selenium.get_webelement(locator).text
                elif label in date_fields:
                    locator = npsp_lex_locators["erd"]["formatted_date"].format(label)
                    actual_value = self.selenium.get_webelement(locator).text
                else:
                    locator = npsp_lex_locators["erd"]["formatted_text"].format(label)
                    actual_value = self.selenium.get_webelement(locator).text

                    if self.npsp.check_if_element_exists(locator):
                        print(f"element exists {locator}")
                        actual_value = self.selenium.get_webelement(locator).text
                        print(f"actual value is {actual_value}")
                        self.builtin.log(f"actual value is {actual_value}")
                        assert (
                            value == actual_value
                        ), "Expected {} value to be {} but found {}".format(
                            label, value, actual_value
                        )
                    else:
                        self.builtin.log("element Not found")
        else:
            for label, value in kwargs.items():
                self.npsp.navigate_to_and_validate_field_value(
                    label, "contains", value, section
                )

    def get_next_payment_date_number(self, paynum):
        """Returns the next payment date from the list of payment schedules taking in the payment number as input
           |Example
           |  Get Next Payment Date Number   2   #gets the 2nd installment payment date form the list of payment dates
        """
        datefield = npsp_lex_locators["erd"]["installment_date"].format(int(paynum))
        installment_date = self.selenium.get_webelement(datefield).text
        
        # This is to format the date by removing the trailing 0 which is being the common format across
        # 01/06/2020 -> 1/6/2020
        tokens = installment_date.split('/')
        dd = tokens[0].replace("0","")
        mm = tokens[1].replace("0","")
        newString = f"{dd}/{mm}/{tokens[2]}"
        return newString

    @capture_screenshot_on_error
    def validate_current_and_next_year_values(self, amount):
        """Takes in the parameter current installment payment (amount)
        calculates the current and next year value payments and
        validates them with the values displayed on the UI. """
        installmentrow = npsp_lex_locators["erd"]["installment_row"]
        installments = self.selenium.get_webelements(installmentrow)
        count = len(installments)
        if count == 0:
            raise Exception("Zero installments found")
        else:
            print(f"Number of installments created is {count}")
            i = 1
            curr_year_value = 0
            next_year_value = 0
            values = {}
            while i < count:
                datefield = npsp_lex_locators["erd"]["installment_date"].format(i)
                installment_date = self.selenium.get_webelement(datefield)
                actual_date = self.selenium.get_webelement(installment_date).text
                year = datetime.strptime(actual_date, "%m/%d/%Y").year
                curr_year = datetime.now().year
                next_year = (datetime.now() + relativedelta(years=1)).year
                if curr_year == year:
                    curr_year_value = curr_year_value + int(amount)
                elif next_year == year:
                    next_year_value = next_year_value + int(amount)
                i = i + 1
            values['Current Year Value']=f"${curr_year_value}.00"
            values['Next Year Value']=f"${ next_year_value}.00"
            self.validate_field_values_under_section("Statistics",**values)

    @capture_screenshot_on_error
    def validate_upcoming_schedules(self, num_payments, startdate, dayofmonth):
        """Takes in the parameter (number of payments) and the donation start date
        verifies that the payment schedules created on UI reflect the total number
        verifies that the next payment dates are reflected correctly for all the schedules"""

        installmentrow = npsp_lex_locators["erd"]["installment_row"]
        installments = self.selenium.get_webelements(installmentrow)
        count = len(installments)
        print(f"Number of installments created is {count}")
        assert count == int(num_payments), "Expected installments to be {} but found {}".format(num_payments, count)
        if count == int(num_payments):
            i = 1
            while i < count:
                datefield = npsp_lex_locators["erd"]["installment_date"].format(i)
                installment_date = self.selenium.get_webelement(datefield)
                date_object = datetime.strptime(startdate, "%m/%d/%Y").date()
                expected_date = (date_object + relativedelta(months=+i)).replace(
                    day=int(dayofmonth)
                )
                actual_date = self.selenium.get_webelement(installment_date).text
                formatted_actual = datetime.strptime(actual_date, "%m/%d/%Y").date()
                assert (
                    formatted_actual == expected_date
                ), "Expected date to be {} but found {}".format(
                    expected_date, formatted_actual
                )
                i = i + 1
