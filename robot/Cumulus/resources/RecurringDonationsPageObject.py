from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from datetime import datetime
import time
from logging import exception
from dateutil.relativedelta import relativedelta
import time


@pageobject("Listing", "npe03__Recurring_Donation__c")
class RDListingPage(BaseNPSPPage, ListingPage):
    object_name = "npe03__Recurring_Donation__c"

    @capture_screenshot_on_error
    def wait_for_rd2_modal(self):
        """Based on the button name (Cancel)  or (Save) on the modal footer, selects and clicks on the respective button"""
        btnlocator = npsp_lex_locators["button-with-text"].format("Save")
        self.builtin.sleep(2,"Wait for the page to load fully")
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.wait_until_page_contains_element(btnlocator,timeout=60,error="Recurring Donations Modal window did not open")
        self.selenium.wait_until_element_is_visible(btnlocator,60)
    
    @capture_screenshot_on_error
    def click_rd2_modal_button(self, name):
        """Based on the button name (Cancel)  or (Save) on the modal footer, selects and clicks on the respective button"""
        btnlocator = npsp_lex_locators["button-with-text"].format(name)
        self.builtin.sleep(2,"Wait for the elevate message to appear on the modal")
        self.selenium.wait_until_element_is_visible(btnlocator,60)
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
            self.selenium.scroll_element_into_view(selection_value)
            self.selenium.click_element(selection_value)
        else:
            self.builtin.log(f"dropdown element {dropdown} not present")

    @capture_screenshot_on_error
    def populate_rd2_modal_form(self, **kwargs):
        """Populates the RD2 modal form fields with the respective fields and values"""
        self.builtin.sleep(1,"For Rd2 modal dropdown values to get populated")
        ns=self.npsp.get_npsp_namespace_prefix()
        for key, value in kwargs.items():
            locator = npsp_lex_locators["erd"]["modal_input_field"].format(key)
            # Recurring Donation Name field only appears on a regression org hence this check
            if key == "Recurring Donation Name":
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.salesforce._populate_field(locator, value)
                else:
                    self.builtin.log(f"Element {key} not found")
            if key in ("Amount","Number of Planned Installments"):
                if self.npsp.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.salesforce._populate_field(locator, value)
                else:
                    self.builtin.log(f"Element {key} not found")
            if key in ("Donor Type","Payment Method","Day of Month","Recurring Type"):
                self.select_value_from_rd2_modal_dropdown(key, value)
            if key in ("Account", "Contact"):
                self.salesforce.populate_lookup_field(key, value)

@pageobject("Details", "npe03__Recurring_Donation__c")
class RDDetailPage(BaseNPSPPage, DetailPage):
    object_name = "npe03__Recurring_Donation__c"

    def _is_current_page(self):
        """ Verify we are on the Recurring Donations Detail page
            by verifying that the url contains '/view'
        """
        for i in range(3):
            print(f"attempt to load page {i}")
            time.sleep(2)
            self.selenium.location_should_contain(
                "view",
                message="Current page is not a Recurring Donations record view",
            )
            locator = npsp_lex_locators["bge"]["button"].format("Edit")
            self.selenium.wait_until_page_contains_element(locator, error="Recurring donations Details page did not load fully")
            edit_button = self.selenium.get_webelement(locator)
            if self.npsp.check_if_element_displayed(edit_button):
                return
            else:
                time.sleep(2)
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
        self.selenium.wait_until_element_is_visible(edit_button,60)
        self.selenium.click_element(locator)
        time.sleep(3)
        btnlocator = npsp_lex_locators["button-with-text"].format("Save")
        self.selenium.wait_until_element_is_visible(btnlocator,60)
        self._populate_edit_status_values(**kwargs)
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.click_element(btnlocator)

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
                    self.selenium.wait_until_element_is_visible(selection_value,60)
                    self.selenium.scroll_element_into_view(selection_value)
                    self.selenium.click_element(selection_value)
                else:
                    self.builtin.log(f"Element {key} not present")

    @capture_screenshot_on_error
    def pause_recurring_donation(self, type=None):
        """Finds the pause button on the recurring donations details
        view page, clicks the button and waits for the modal to appear"""
        locator = npsp_lex_locators["bge"]["button"].format("Pause")
        pause_button = self.selenium.get_webelement(locator)
        self.selenium.wait_until_element_is_visible(pause_button,60)
        self.builtin.sleep(1)
        self.npsp._loop_is_text_present("Pause")
        self.selenium.click_element(locator)
        if type != "Closed":
            btnlocator = npsp_lex_locators["button-with-text"].format("Save")
            self.selenium.wait_until_element_is_visible(btnlocator,60)

    @capture_screenshot_on_error
    def populate_pause_modal(self,**kwargs):
        """ Populate the values in the pause recurring donation modal
		based on the key value pair options in the kwargs passed as parameter
		| Populate Pause Modal
        | ...	                  Paused Reason=Card Expired
        | ...	                  Date=${date}     """
        for key, value in kwargs.items():
           if key in ("Paused Reason"):
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
           elif key in ("Date"):
               for v in value:
                  checkbox =  npsp_lex_locators["erd"]["pause_date_checkbox"].format(v)
                  time.sleep(1)
                  if (checkbox.is_selected() == False):
                    self.selenium.click_element(checkbox)
                  else:
                    self.builtin.log("This checkbox is already in the expected status", "WARN")
           else:
               raise Exception("Key not supported expected keys <Paused Reason> or <Date>")
           
        btnlocator = npsp_lex_locators["button-with-text"].format("Save")
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.click_element(btnlocator)
        self.salesforce.wait_until_modal_is_closed()


    @capture_screenshot_on_error
    def populate_pause_modal(self,**kwargs):
        """ Populate the values in the pause recurring donation modal
		based on the key value pair options in the kwargs passed as parameter
		| Populate Pause Modal
        | ...	                  Paused Reason=Card Expired
        | ...	                  Date=${date}     """
        for key, value in kwargs.items():
            if key in ("Paused Reason"):
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
                    
            if key in ("Date"):
                for date in value:
                    checkbox =  npsp_lex_locators["erd"]["pause_date_checkbox"].format(date)
                    time.sleep(1)
                    self.selenium.click_element(checkbox)
            if "Validate" in key:
                self.validate_message_text(value)
        btnlocator = npsp_lex_locators["button-with-text"].format("Save")
        self.selenium.scroll_element_into_view(btnlocator)
        self.selenium.click_element(btnlocator)
        self.salesforce.wait_until_modal_is_closed()

    
    @capture_screenshot_on_error
    def validate_message_text(self,txt):
        """Find the element containing warning message on the pause modal and
        asserts the text displayed matches with the expected text"""
        locator = npsp_lex_locators["erd"]["warning_message"].format(txt)
        self.selenium.wait_until_element_is_visible(locator)

    @capture_screenshot_on_error
    def verify_pause_text_next_to_installment_date(self, *dates):
        """Accepts a list of dates and validates the presence of date element with the paused text next to it """
        for date in dates:
            locator = npsp_lex_locators["erd"]["date_with_paused_txt"].format(date)
            self.selenium.wait_until_element_is_visible(locator)
            self.selenium.element_text_should_be(locator, date)

    @capture_screenshot_on_error
    def verify_schedule_warning_messages_present(self):
        """Verify that the schedule warning messages are present when there are no schedules"""
        time.sleep(2)
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

    def get_next_payment_date_number(self, paynum, format=True):
        """Returns the next payment date from the list of payment schedules taking in the payment number as input
           The date if formatted to ignore the preceding zeros. But if format is set to false, the date is returned
           as is without any formatting
           |Example
           |  Get Next Payment Date Number   2   #gets the 2nd installment payment date form the list of payment dates
           |  Get Ney Payment Date Number    1    False    # gets the 1st installment payment date without any formatting
        """
        datefield = npsp_lex_locators["erd"]["installment_date"].format(int(paynum))
        installment_date = self.selenium.get_webelement(datefield).text

        # This is to format the date by removing the trailing 0 which is being the common format across
        # 01/06/2020 -> 1/6/2020
        if format == True:
            tokens = installment_date.split('/')
            dd = tokens[0].lstrip('0')
            mm = tokens[1].lstrip('0')
            newString = f"{dd}/{mm}/{tokens[2]}"
        else:
            tokens = installment_date.split('/')
            dd = tokens[0]
            mm = tokens[1]
            newString = f"{dd}/{mm}/{tokens[2]}"
        return newString

    @capture_screenshot_on_error
    def validate_current_and_next_year_values(self, amount, rdtype=None):
        """Takes in the parameter current installment payment (amount) and an optional field of the rd type
        calculates the current and next year value payments and validates them with the values displayed on the UI. """
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
            next_year_count = 0
            values = {}
            while i <= count:
                datefield = npsp_lex_locators["erd"]["installment_date"].format(i)
                installment_date = self.selenium.get_webelement(datefield)
                actual_date = self.selenium.get_webelement(installment_date).text
                paused_locator = npsp_lex_locators["erd"]["date_with_paused_txt"].format(actual_date)
                year = datetime.strptime(actual_date, "%m/%d/%Y").year
                curr_year = datetime.now().year
                next_year = (datetime.now() + relativedelta(years=1)).year
                # increment the current year value if there is no paused text next to installment date
                if curr_year == year and not self.npsp.check_if_element_exists(paused_locator):
                    curr_year_value = curr_year_value + int(amount)
                # increment the next year value if there is no paused text next to installment date
                elif next_year == year and not self.npsp.check_if_element_exists(paused_locator):
                    next_year_value = next_year_value + int(amount)
                if next_year == year:
                    next_year_count = next_year_count + 1
                i = i + 1
                
             # This logic handles the scenario if the recurring donation is of type open, the entire year installments
             # are accounted in the calculation for next year value
            if rdtype == "Open":
                next_year_value = next_year_value + (12-next_year_count)*int(amount)
            values['Current Year Value']=f"${curr_year_value}.00"
            #values['Next Year Value']=f"${ next_year_value}.00"
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
        date_object = datetime.strptime(startdate, "%m/%d/%Y").date()
        # Create a list to store expected dates and actual dates from the ui. Compare the dates and throw exception
        expected_dates = []
        actual_dates = []
        if count == int(num_payments):
            i = 1
            j = 1
            while i <= count:
                datefield = npsp_lex_locators["erd"]["installment_date"].format(i)
                installment_date = self.selenium.get_webelement(datefield)
                actual_date = self.selenium.get_webelement(installment_date).text
                formatted_actual = datetime.strptime(actual_date, "%m/%d/%Y").date()
                actual_dates.append(formatted_actual)
                i = i + 1
            while j <= count+1:
                expected_date = date_object
                expected_dates.append(expected_date)
                date_object = (expected_date + relativedelta(months=+1))
                j = j + 1
            check =  any(item in expected_dates for item in actual_dates)
            
            assert (
                check == True
            ), "expected_dates {} doesn't match the actual_dates {}".format(
               expected_date, formatted_actual
            )
        else:
            raise Exception("Number of payment installments do not match.")