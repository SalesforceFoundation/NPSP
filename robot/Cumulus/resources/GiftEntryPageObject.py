import time
import re
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from selenium.common.exceptions import ElementClickInterceptedException
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

OID_REGEX = r"^(%2F)?([a-zA-Z0-9]{15,18})$"

@pageobject("Landing", "GE_Gift_Entry")
class GiftEntryLandingPage(BaseNPSPPage, BasePage):

    
    def _go_to_page(self):
        """To go to Gift Entry page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()

    def _is_current_page(self):
        """
        Verifies that current page is Gift Entry landing page
        """
        self.selenium.wait_until_location_contains("GE_Gift_Entry", timeout=60, 
                                                   message="Current page is not Gift Entry landing page")
        locator=npsp_lex_locators["gift_entry"]["id"].format("datatable Batches")                                           
        self.selenium.wait_until_page_contains_element(locator)                                               


    def click_gift_entry_button(self,title):
        """clicks on Gift Entry button identified with title"""
        locator=npsp_lex_locators["gift_entry"]["button"].format(title)
        self.selenium.wait_until_page_contains_element(locator)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_element(locator)  

    def select_template_action(self,name,action):
        """From the template table, select template with name and select an action from the dropdown"""
        locator=npsp_lex_locators["gift_entry"]["actions_dropdown"].format(name)
        self.selenium.click_element(locator)
        element=self.selenium.get_webelement(locator)
        status=element.get_attribute("aria-expanded")
        if status=="false":
            self.selenium.wait_until_page_contains("Clone")    
        self.selenium.click_link(action)
        if action=="Edit" or action=="Clone":
            self.selenium.wait_until_page_contains("Gift Entry Template Information")
        elif action=="Delete":
            self.selenium.wait_until_page_does_not_contain(name)     

    def verify_template_is_not_available(self,template):
        """Verify that a gift template is not available for selection while creating a new batch"""
        field=npsp_lex_locators["adv_mappings"]["field_mapping"].format("Template")
        self.selenium.click_element(field)
        element=self.selenium.get_webelement(field)
        status=element.get_attribute("aria-activedescendant")
        if status is not None:
            self.selenium.page_should_not_contain(template)
        else:
            self.selenium.wait_until_page_contains("Default Gift Entry Template")
            self.selenium.page_should_not_contain(template)  
        self.selenium.click_button("Cancel")

    def select_template(self,template):
        """selects the specified template while creating a new batch"""
        field=npsp_lex_locators["adv_mappings"]["field_mapping"].format("Template")
        self.selenium.wait_until_page_contains_element(field)
        self.selenium.click_element(field)
        self.selenium.wait_until_page_contains(template)
        self.npsp.click_span_button(template)  
        self.selenium.click_button("Next")    
    
    def get_template_record_id(self,template):
        """ Parses the current url to get the object id of the current record.
            Expects url format like: [a-zA-Z0-9]{15,18}
        """
        locator=npsp_lex_locators["link-text"].format(template)
        self.selenium.wait_until_page_contains_element(locator)
        element = self.selenium.get_webelement(locator)
        e=element.get_attribute("href")
        print(f"url is {e}")
        for part in e.split("="):
            oid_match = re.match(OID_REGEX, part)
            if oid_match is not None:
                return oid_match.group(2)
        raise AssertionError("Could not parse record id from url: {}".format(e))

    def store_template_record_id(self,template):
        """ Parses the template href to get the object id of the current record.
            Expects url format like: [a-zA-Z0-9]{15,18}
        """
        id=self.get_template_record_id(template) 
        self.salesforce.store_session_record("Form_Template__c",id)   


@pageobject("Template", "GE_Gift_Entry")
class GiftEntryTemplatePage(BaseNPSPPage, BasePage):


    def _is_current_page(self):
        """
        Verifies that current page is Template Builder edit page
        """
        self.selenium.wait_until_page_contains("Gift Entry Template Information")       
    
    def enter_value_in_field(self,**kwargs):
        """Enter value in specified field"""
        for key,value in kwargs.items():
            if key=='Description':
                locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"textarea")
                self.selenium.wait_until_page_contains_element(locator)
                self.salesforce._populate_field(locator, value)
            else:
                locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
                self.selenium.wait_until_page_contains_element(locator)
                self.salesforce._populate_field(locator, value)   

    @capture_screenshot_on_error
    def select_object_group_field(self,object_group,field):
        """Select the specified field under specified object group 
           to add the field to gift entry form and verify field is added"""
        locator=npsp_lex_locators["gift_entry"]["form_object_dropdown"].format(object_group)
        self.salesforce._jsclick(locator)
        element=self.selenium.get_webelement(locator)
        status=element.get_attribute("aria-expanded")
        if status=="false":
            time.sleep(2)       
        field_checkbox=npsp_lex_locators["gift_entry"]["field_input"].format(field,"input")  
        check=self.selenium.get_webelement(field_checkbox)
        if not check.is_selected():
            try:
                self.salesforce._jsclick(field_checkbox)
            except ElementClickInterceptedException:
                self.selenium.execute_javascript("window.scrollBy(0,0)")
                self.salesforce._jsclick(field_checkbox)
        label=": "+field    
        self.selenium.wait_until_page_contains(label)


    @capture_screenshot_on_error                
    def fill_template_form(self,**kwargs):
        """Add default values to template builder form fields or set fields as required. 
        Key is field main label name and value is again another dictionary of field type and value
        ex: Payment: Payment Method is Main Label with Default Value as field type and ChecK is value"""
        self.selenium.execute_javascript("window.scrollBy(0,0)")
        for field,option in kwargs.items():
            for section,value in option.items():
                if section=="Required":
                    label=f'{section} {field}'
                    if value=='checked':
                        field_checkbox=npsp_lex_locators["gift_entry"]["field_input"].format(label,"input")
                        self.selenium.scroll_element_into_view(field_checkbox)
                        cb_loc=self.selenium.get_webelement(field_checkbox)
                        if not cb_loc.is_selected():
                            self.salesforce._jsclick(field_checkbox)
                    elif value=='unchecked': 
                        field_checkbox=npsp_lex_locators["gift_entry"]["field_input"].format(label,"input")
                        self.selenium.scroll_element_into_view(field_checkbox)
                        cb_loc=self.selenium.get_webelement(field_checkbox)
                        if cb_loc.is_selected():
                            self.salesforce._jsclick(field_checkbox)
                elif section=="Default Value":
                    key=f'{section} {field}'
                    field_loc=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
                    placeholder=self.selenium.get_webelement(field_loc).get_attribute("placeholder")
                    self.selenium.scroll_element_into_view(field_loc)
                    try:
                        self.selenium.click_element(field_loc)
                    except ElementClickInterceptedException:
                        self.selenium.execute_javascript("window.scrollBy(0,100)")
                        self.selenium.click_element(field_loc)    
                    if placeholder=="Select an Option":
                        popup=npsp_lex_locators["flexipage-popup"]
                        self.selenium.wait_until_page_contains_element(popup)
                        option=npsp_lex_locators["span_button"].format(value)
                        self.selenium.click_element(option)
                    elif placeholder=="Search...":
                        self.salesforce.populate_lookup_field(key,value)
                    elif "Date" in field:
                        locator=npsp_lex_locators["bge"]["datepicker_open"].format("Date")  
                        self.selenium.wait_until_page_contains_element(locator)
                        self.selenium.click_button(value)    
                        self.selenium.wait_until_page_does_not_contain_element(locator,error="could not open datepicker")
                    else:
                        self.salesforce._populate_field(field_loc,value) 
    
    def add_field_bundle_to_new_section(self,bundle):
        """Adds the specified field bundle to the template builder form if not already added"""
        try:
            self.selenium.click_button("Add Section")
        except ElementClickInterceptedException:
            self.selenium.execute_javascript("window.scrollBy(0,100)")
            self.selenium.click_button("Add Section")
        checkbox=npsp_lex_locators["gift_entry"]["field_input"].format(bundle,"input")
        self.selenium.scroll_element_into_view(checkbox)
        cb_loc=self.selenium.get_webelement(checkbox)
        if not cb_loc.is_selected():
            try:
                self.salesforce._jsclick(checkbox) 
            except ElementClickInterceptedException:
                self.selenium.execute_javascript("window.scrollBy(0,100)")
                self.salesforce._jsclick(checkbox)  

    def add_batch_table_columns(self,*args):
        """Adds specified batch columns to the visible section if they are not already added"""
        first_element=True
        position=0
        for i in args:
            locator=npsp_lex_locators["gift_entry"]["duellist"].format("Available Fields",i)
            if self.npsp.check_if_element_exists(locator):
                if first_element:
                    self.selenium.click_element(locator)
                    first_element=False
                    position=args.index(i)
                else:
                    self.selenium.click_element(locator,'COMMAND')
        self.selenium.click_button("Move selection to Visible Fields")
        verify_field=npsp_lex_locators["gift_entry"]["duellist"].format("Available Fields",args[position])
        print (f'verify locator is {verify_field}')
        self.selenium.wait_until_page_does_not_contain_element(verify_field)


            



    

@pageobject("Form", "Gift Entry")
class GiftEntryFormPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Verifies that current page is Gift Entry form page
        """
        self.selenium.wait_until_page_contains("Donor Information")

    def verify_field_default_value(self,**kwargs):
        """verifies that the field contains given default value
        where key=field name and value=default value"""
        for key,value in kwargs.items():
            field=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
            self.selenium.wait_until_page_contains_element(field)
            time.sleep(.5)
            element=self.selenium.get_webelement(field)
            default_value=element.get_attribute("value")
            assert value == default_value, f"Expected {key} default value to be {value} but found {default_value}"

    def fill_gift_entry_form(self,**kwargs):
        """Fill the gift entry form fields with specified values. 
        Key is field name and value is value to be entered for field """
        for key,value in kwargs.items():
            locator=npsp_lex_locators["gift_entry"]["id"].format(key)
            element=self.selenium.get_webelement(locator)
            type=element.get_attribute("data-qa-locator")
            print(f"type is {type}")
            if 'autocomplete' in type :
                self.salesforce._populate_field(locator,value)
                value_locator=npsp_lex_locators["gift_entry"]["id"].format(value)
                self.selenium.wait_until_page_contains_element(value_locator)
                self.selenium.click_element(value_locator)
            elif 'combobox' in type :
                field_locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
                self.selenium.click_element(field_locator)
                popup=npsp_lex_locators["flexipage-popup"]
                self.selenium.wait_until_page_contains_element(popup)
                option=npsp_lex_locators["span_button"].format(value)
                self.selenium.click_element(option)
            elif 'textarea' in type :
                field_locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"textarea")
                self.salesforce._populate_field(field_locator,value)
            else:
                field_locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
                self.salesforce._populate_field(field_locator,value)

    def verify_error_for_field(self,**kwargs):
        """Verify that the given field contains specified error message
        Key should be field name and value should be the error message expected for field""" 
        for key,value in kwargs.items():
            locator=npsp_lex_locators["gift_entry"]["field_alert"].format(key,value)
            self.selenium.wait_until_page_contains_element(locator)           

    def verify_gift_count(self,count):
        """Verify that the no. of gifts on the page match with count"""
        locator=npsp_lex_locators["gift_entry"]["count"].format("Count of Gifts",count)
        self.selenium.wait_until_page_contains_element(locator)

    def click_field_value_link(self,field_name):
        """clicks on the link present in the given field"""
        value=self.npsp.return_locator_value("bge.value",field_name) 
        self.npsp.click_link_with_text(value)   
