import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "NPSP_Settings")
class NPSPSettingsPage(BaseNPSPPage, BasePage):


    def _go_to_page(self, filter_name=None):
        """To go to NPSP Settings page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        namespace= self.cumulusci.get_namespace_prefix("Nonprofit Success Pack") or self.cumulusci.get_namespace_prefix("Nonprofit Success Pack Managed Feature Test")
        object_name = "{}{}".format(namespace, name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame","Nonprofit Success Pack Settings")
        self.npsp.choose_frame("Nonprofit Success Pack Settings")

    def open_main_menu(self,title):
        """Waits for the menu item to load and clicks to expand menu"""
        self.selenium.wait_until_page_contains(title,
                                               error=f"{title} link was not found on the page")
        # There are two elements that have donations and this hack is needed to avoid the
        # confusion of which element to pick
        if title == "Donations":
            locator=npsp_lex_locators['npsp_settings']['donations_link'].format(title)
            self.selenium.wait_until_element_is_visible(locator)
            self.salesforce._jsclick(locator)
        else:
            #self.npsp.click_link_with_text(title)
            locator=npsp_lex_locators["npsp_settings"]["main_menu_link"].format(title)
            self.selenium.wait_until_page_contains_element(locator,
                                               error=f"click on {title} link was not successful even after 30 seconds")
            self.salesforce._jsclick(locator)
        self.selenium.capture_page_screenshot()

    def open_sub_link(self,title):
        """Waits for the link to load and clicks to make a part of page active"""
        self.selenium.wait_until_page_contains(title,
                                               error=f"{title} link was not found on the page")
        self.npsp.click_link_with_text(title)
        if title=='Status to State Mapping':
            locator=npsp_lex_locators['npsp_settings']['erd_status_mapping_header'].format(title)
            self.selenium.wait_until_page_contains_element(locator, error=f"Couldn't find status mappings on the page")
        else:
            locator=npsp_lex_locators['npsp_settings']['panel_sub_link'].format(title)
            self.selenium.wait_until_page_contains_element(locator,
                                                       error=f"click on {title} sublink was not successful even after 30 seconds")
        self.selenium.capture_page_screenshot()

    @capture_screenshot_on_error
    def verify_sub_link_present(self, title, bool):
        """ Asserts if the sublink is present or not present
            eg: Verify Sub Link Present     <Linkoption>   True/False
        """
        locator=npsp_lex_locators['npsp_settings']['panel_sub_link'].format(title)
        assert bool == str(self.npsp.check_if_element_exists(locator)), "Expected {} present value to be {} but found {}".format(
            title, bool, self.npsp.check_if_element_exists(locator)
        )

    @capture_screenshot_on_error
    def click_settings_button (self,panel_id,btn_value):
        """clicks on the buttons on npsp settings object using panel id and button value"""
        locator=npsp_lex_locators['npsp_settings']['batch-button'].format(panel_id,btn_value)
        self.selenium.wait_until_page_contains_element(locator,
                                                       error=f"{btn_value} did not appear on page")
        self.selenium.wait_until_element_is_visible(locator, timeout=60)
        self.salesforce._jsclick(locator)
        self.selenium.capture_page_screenshot()

    def select_value_from_list(self,list_name,value):
        '''Selects value from list identified by list_name.
           uses selenium select from list by label keyword
        '''
        locator = npsp_lex_locators['npsp_settings']['list'].format(list_name)
        loc = self.selenium.get_webelement(locator)
        self.selenium.set_focus_to_element(locator)
        self.selenium.select_from_list_by_label(loc,value)

    def edit_selection(self,list_name,value):
        """waits for edit mode and selects value from the list"""
        save_button=npsp_lex_locators['npsp_settings']['batch-button'].format('idPanelCon','Save')
        self.selenium.wait_until_page_contains_element(save_button,
                                                       error=f"Edit mode is not active")
        self.select_value_from_list(list_name,value)
        time.sleep(2) # waiting for 2 seconds in case there is slowness

    @capture_screenshot_on_error
    def verify_selection(self,list_name,value):
        """waits to exit edit mode and verifies list contains specified value"""
        edit_button=npsp_lex_locators['npsp_settings']['batch-button'].format('idPanelCon','Edit')
        self.selenium.wait_until_page_contains_element(edit_button,
                                                       error=f"Still in Edit mode")
        locator = npsp_lex_locators['npsp_settings']['list_val'].format(list_name,value)
        self.selenium.wait_until_page_contains_element(locator, error=f"{list_name} did not contain {value}")

    @capture_screenshot_on_error
    def click_toggle_button(self, page_name):
        """ specify the partial id of submenu under which the checkbox exists """
        locator = npsp_lex_locators["npsp_settings"]["checkbox"].format(page_name)
        self.selenium.wait_until_element_is_enabled(locator,error="Checkbox could not be found on the page")
        self.salesforce.scroll_element_into_view(locator)
        self.selenium.capture_page_screenshot()
        self.selenium.get_webelement(locator).click()
        self.selenium.capture_page_screenshot()

    @capture_screenshot_on_error
    def wait_for_message(self,message):
        """Waits for the text passed in message to be displayed on the page for 6 min"""
        i=0
        while True:
            if i<=12:
                try:
                    self.selenium.page_should_contain(message)
                    break
                except Exception:
                    time.sleep(10)
                    i += 1
            else:
                raise AssertionError(
                    f"Timed out waiting for {message} to display"
                )

    def click_configure_advanced_mapping(self):
        """clicks on Configure Advanced Mapping and waits for Manage Advanced Mapping page to load
           and loads the page object for that page"""
        locator=npsp_lex_locators['id'].format("navigateAdvancedMapping")
        self.selenium.click_element(locator)
        self.pageobjects.current_page_should_be("Custom", "BDI_ManageAdvancedMapping")
        self.selenium.wait_until_page_contains("Account",timeout=30, error="Objects did not load in 30 seconds")

    def verify_advanced_mapping_is_not_enabled(self):
        """Verifies that advanced mapping is not enabled by default
           By checking 'Configure Advanced Mapping' is not visible on the page"""
        locator=npsp_lex_locators['id'].format("navigateAdvancedMapping")
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            classname=ele.get_attribute("class")
            if 'slds-hide' in classname:
                self.builtin.log("As expected Advanced Mapping is not enabled by default")
            else:
                raise Exception("Advanced Mapping is already enabled. Org should not have this enabled by default")


    def enable_advanced_mapping_if_not_enabled(self):
        """Checks if advanced mapping is Enabled and enables if not enabled"""
        locator=npsp_lex_locators['id'].format("navigateAdvancedMapping")
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            classname=ele.get_attribute("class")
            if 'slds-hide' in classname:
                self.builtin.log("Advanced Mapping is not enabled by default")
                self.click_toggle_button("Advanced Mapping")
                self.wait_for_message("Advanced Mapping is enabled")
                self.npsp.choose_frame("Nonprofit Success Pack Settings")
            else:
                self.builtin.log("Advanced Mapping is already enabled")

    @capture_screenshot_on_error
    def Enable_customizable_rollups_if_not_enabled(self):
        """Checks if advanced mapping is Enabled and enables if not enabled"""
        locator=npsp_lex_locators['id'].format("navigateCRLPs")
        if self.npsp.check_if_element_exists(locator):
            self.builtin.log("Customizable Rollups is already enabled")
        else:
            self.builtin.log("Customizable Rollups is not enabled by default, enabling it")
            self.click_toggle_button("Customizable Rollups")
            self.selenium.wait_until_page_contains_element(locator,timeout=90)
            self.builtin.log("Customizable Rollups is enabled")

    def verify_gift_entry_is_not_enabled(self):
        """Verifies that gift entry is not enabled by default
           If already enabled, disables it"""
        locator=npsp_lex_locators['id'].format("enableGiftEntryToggle")
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            att=ele.get_attribute("checked")
            if att=="true":
                self.builtin.log("Gift Entry is already enabled. Org should not have this enabled by default")
                self.click_toggle_button("Gift Entry")
                self.wait_for_message("Gift Entry Disabled")
            else:
                self.builtin.log("As expected Gift Entry is Disabled")

    def enable_gift_entry_if_not_enabled(self):
        """checks to make sure advanced mapping is enabled and enables gift entry if not enabled """
        self.enable_advanced_mapping_if_not_enabled()
        locator=npsp_lex_locators['id'].format("enableGiftEntryToggle")
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            att=ele.get_attribute("checked")
            if att=="true":
                self.builtin.log("Gift Entry is already enabled.")
            else:
                self.click_toggle_button("Gift Entry")
                self.wait_for_message("Gift Entry Enabled")
                self.npsp.choose_frame("Nonprofit Success Pack Settings")


    def check_crlp_not_enabled_by_default(self):
        """Verifies that customizable rollups settings is not enabled by default
           By checking 'Configure Customizable Rollups' is not visible on the page"""
        locator=npsp_lex_locators['id'].format("navigateCRLPs")
        ispresent = False
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            classname=ele.get_attribute("value")
            if 'Configure Customizable Rollups' in classname:
                self.builtin.log("This Org has Customizable Rollups Enabled")
                isPresent = True
            return isPresent

    @capture_screenshot_on_error
    def check_metadeploy_exists(self):
        """Check if the rd2 metadeploy link is enabled """
        locator=npsp_lex_locators["erd"]["rd2_installed"]
        isPresent = False
        if self.npsp.check_if_element_displayed(locator):
            isPresent = True
        return isPresent

    @capture_screenshot_on_error
    def check_rd2_is_enabled(self):
        """Verifies that Enhanced Recurring Donations is enabled on the org"""
        enabled = False
        if self.npsp.check_submenu_link_exists("Upgrade to Enhanced Recurring Donations"):
            self.npsp.click_link_with_text("Upgrade to Enhanced Recurring Donations")
            time.sleep(2)    #This sleep is necessary in this particular scenario
            if self.check_metadeploy_exists():
                enabled = True
        return enabled

    @capture_screenshot_on_error
    def verify_status_to_state_mappings(self, **kwargs):
        """verifies the default status to state mappings for recurring donations"""
        for key,value in kwargs.items():
            locator=npsp_lex_locators['npsp_settings']['erd_state_status_mapping'].format(key)
            self.selenium.wait_until_page_contains_element(locator, error=f"Couldn't find {key} on the page")
            if self.npsp.check_if_element_exists(locator):
                print(f"element exists {locator}")
                actual_value=self.selenium.get_webelement(locator).text
                print(f"actual mapping found for {key} is {actual_value}")
                assert value == actual_value, "Expected {} value to be {} but found {}".format(key,value, actual_value)
            else:
                print("Right keys under status mapping fields table not found")

    @capture_screenshot_on_error
    def set_batch_number_format_status(self,number_format,status):
        """Activates or Deactivates the given batch number format by clicking on dropdown and selecting option
        And verifies that the format has been activated or deactivated based on selection"""
        locator=npsp_lex_locators['npsp_settings']['table_dropdown'].format(number_format)
        self.selenium.get_webelement(locator).click()
        if status.lower()=='deactivate':
            self.selenium.wait_until_page_contains("Deactivate")
            self.selenium.click_link("Deactivate")
            self.builtin.sleep(1,"To allow time for format to be deactivated")
            self.npsp.verify_table_contains_row("datatable",number_format,Active="False")
        elif status.lower()=='activate':
            self.selenium.wait_until_page_contains("Activate")
            self.selenium.click_link("Activate")
            self.builtin.sleep(1,"To allow time for format to be activated")
            self.npsp.verify_table_contains_row("datatable",number_format,Active="True")
        else:
            raise Exception(f'{status} is invalid, please select either Activate or Deactivate')


