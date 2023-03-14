from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators



@pageobject("Custom", "CustomRollupSettings")
class CustomRollupSettingsPage(BaseNPSPPage, BasePage):

    def navigate_to_crlpsettings(self, filter_name=None):
        """ Click on the Navigate CRLP Button and wait for the page to load """
        locator = npsp_lex_locators["id"].format("navigateCRLPs")
        self.selenium.click_element(locator)
        self.selenium.wait_until_location_contains(
            "/one/one.app",
            timeout=60,
            message="custom rollup settings page did not load in 1 min",
        )
        self.npsp.wait_for_locator("frame_new", "vfFrameId", "vfFrameId")
        self.npsp.choose_frame("vfFrameId")
        link = npsp_lex_locators["link-text"].format("Back to NPSP Settings")
        self.selenium.wait_until_page_contains_element(
            link, error="Current page is not a customizable rollups setting view"
        )

    def _is_setting_present(self, object, name):
        """ Search for the presence of an active crlp setting record already. Return a boolean value accordingly
         """
        formatted = object + ": " + name
        isPresent = False
        search_results = npsp_lex_locators["crlps"]["active_setting_record"].format(
            formatted
        )
        elements = int(self.selenium.get_element_count(search_results))
        if elements == 0:
            print("crlp setting record Not found")
        else:
            isPresent = True
            print("crlp setting already exists")
        return isPresent

    def _is_filter_present(self, filtername):
        """ Search for the presence of an active crlp filter setting record already. Return a boolean value accordingly
		"""
        isPresent = False
        filter = npsp_lex_locators['button-with-text'].format(filtername)
        elements = int(self.selenium.get_element_count(filter))
        if elements == 0:
            print("Filter Group Not found")
        else:
            isPresent = True
            print("Filter Group Already Exists")
        return isPresent


    @capture_screenshot_on_error
    def create_new_filter_setting(self, *args, **kwargs):
        """Creates a new filter setting by taking in all the filtering criteria(s)
           Create New Filter Setting
           ...            @{filterPools}        // list of filtering criteria(s)
           ...            &{dict}               // Should contain Filter name and description fields eg: Name=Old Payments    Description=this is a test.
		"""
        view_filter_locator = npsp_lex_locators['button-with-text'].format("View Filter Groups")
        new_filter_locator = npsp_lex_locators['button-with-text'].format("New Filter Group")
        success_toast = npsp_lex_locators['crlps']['success_toast']
        add_filter_btn = npsp_lex_locators['button-with-text'].format("Add")
        self.selenium.wait_until_page_contains_element(view_filter_locator)
        view_filter_button = self.selenium.get_webelement(view_filter_locator)
        self.selenium.click_element(view_filter_button)
        self.selenium.wait_until_page_contains_element(new_filter_locator,60)
        if self._is_filter_present(kwargs['Name']):
            return
        else:
            self.selenium.click_element(new_filter_locator)
            self.selenium.wait_until_page_contains_element(add_filter_btn,60)
            self.npsp.populate_modal_form(**kwargs)
            self._add_filter(*args)
            self.selenium.click_button("Save")
            self.selenium.wait_until_element_is_not_visible(success_toast)


    @capture_screenshot_on_error
    def _add_filter(self, *args):
        """This is a helper method that gets the filter criteria and adds into the filter modal
		"""
        modal_save_btn = npsp_lex_locators['crlps']['modal-button']
        for arg in args:
            add_filter_btn = npsp_lex_locators['button-with-text'].format("Add")
            self.salesforce._jsclick(add_filter_btn)
            self.npsp.populate_modal_form(**arg)
            self.salesforce._jsclick(modal_save_btn)

    @capture_screenshot_on_error
    def create_new_rollup_setting(self, **kwargs):
        """ Wait for the Iframe to be available and switch to the Frame.
            Confirm that a rollup setting of the same type does not exist
            Click on new and create a new rollup settings record
        """
        locator = npsp_lex_locators["button-with-text"].format("New Rollup")
        select_locator = npsp_lex_locators["crlps"]["select_locator"].format(
            "Target Object"
        )
        toast_hide = npsp_lex_locators["crlps"]["success_toast"].format('slds-notify slds-notify_toast slds-theme_success slds-hide')
        toast_visible = npsp_lex_locators["crlps"]["success_toast"].format('slds-notify slds-notify_toast slds-theme_info ')
        if self._is_setting_present(kwargs["Target Object"], kwargs["Target Field"]):
            return
        else:
            self.selenium.wait_until_page_contains_element(locator)
            new_button = self.selenium.get_webelement(locator)
            self.selenium.click_element(new_button)
            self.selenium.wait_until_page_contains_element(select_locator)
            self.populate_crlp_form(**kwargs)
            self.selenium.click_button("Save")
            self.selenium.wait_until_page_contains_element(toast_visible)
            self.selenium.wait_until_page_contains_element(toast_hide)

    @capture_screenshot_on_error
    def clone_rollup(self, rollup_name, **kwargs):
        """ If new rollup doesn't exist - Clone an existing rollup, enter arguments passed  and create new rollup
            If new rollup exists - logs that rollup already exists
        """
        current_rollup = self._check_rollup_status(rollup_name)
        new_label = f'{kwargs["Target Object"]}: {kwargs["Target Field"]}'
        new_rollup = self._check_rollup_status(new_label)
        if current_rollup and not new_rollup:
            locator = npsp_lex_locators["crlps"]["rollup_options"].format(rollup_name)
            select_locator = npsp_lex_locators["crlps"]["select_locator"].format(
                "Target Object"
            )
            toast_hide = npsp_lex_locators["crlps"]["success_toast"].format('slds-notify slds-notify_toast slds-theme_success slds-hide')
            toast_visible = npsp_lex_locators["crlps"]["success_toast"].format('slds-notify slds-notify_toast slds-theme_info ')
            self.salesforce.scroll_element_into_view(locator)
            self.selenium.click_element(locator)
            self.selenium.wait_until_page_contains("Clone")
            self.selenium.click_link("Clone")
            self.selenium.wait_until_page_contains_element(select_locator)
            self.populate_crlp_form(**kwargs)
            self.selenium.click_button("Save")
            self.selenium.wait_until_page_contains_element(toast_visible)
            self.selenium.wait_until_page_contains_element(toast_hide)
        elif not current_rollup:
            raise Exception("Rollup you are trying to clone doesn't exist")
        elif new_rollup:
            self.builtin.log("Rollup {new_rollup} already exists, skipping creation")

    def verify_rollup_exists(self, label):
        """verifies if the rollup with label exists and active, if doesn't exist raises exception
        """
        if self._check_rollup_status(label):
            self.builtin.log("This rollup exists")
        else:
            raise Exception("Rollup does not exist")

    def select_from_list(self, key, value):
        """Selects the specified value from the dropdown identified with key on rollups form"""
        locator = npsp_lex_locators["crlps"]["select_locator"].format(key)
        self.selenium.select_from_list_by_label(locator, value)

    def populate_crlp_form(self, **kwargs):
        """Pass the field name and value as key, value pairs to populate the rollups form"""
        for key, value in kwargs.items():
            if key == "Description":
                self.salesforce.populate_field(key, value)
            else:
                self.select_from_list(key, value)

    def _check_rollup_status(self, label):
        """This is a helper API that checks if the rollup exists and active.
           Returns true if both condtions are met, else returns false """
        ns = self.npsp.get_npsp_namespace_prefix()
        object = ns + "Rollup__mdt"
        field = ns + "Active__c"
        status = False
        query = "SELECT Id FROM {} WHERE {} = True AND Label = '{}'".format(object, field, label)
        record = self.salesforce_api.soql_query(query).get("records", [])
        print(f"record is {record}")
        if len(record) > 0:
            status = True
        return status

