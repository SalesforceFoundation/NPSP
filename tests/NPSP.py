import logging
import re
import time


from robot.libraries.BuiltIn import BuiltIn
from selenium.common.exceptions import ElementNotInteractableException
from selenium.common.exceptions import StaleElementReferenceException
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import WebDriverException
from selenium.webdriver.common.keys import Keys
from SeleniumLibrary.errors import ElementNotFound
from simple_salesforce import SalesforceMalformedRequest
from simple_salesforce import SalesforceResourceNotFound
from locator import npsp_lex_locators
from selenium.webdriver import ActionChains
#import os
#import sys
#sys.path.append(os.path.abspath(os.path.join('..',
#sys.path.append("/Users/skristem/Documents/GitHub/CumulusCI/cumulusci/robotframework/tests")
#import Salesforce


class NPSP(object):
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = 1.0
 
    def __init__(self, debug=False):
        self.debug = debug
        self.current_page = None
        self._session_records = []
        # Turn off info logging of all http requests 
        logging.getLogger('requests.packages.urllib3.connectionpool').setLevel(logging.WARN)
 
    @property
    def builtin(self):
        return BuiltIn()   
 
    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')
  
    @property
    def selenium(self):
        return self.builtin.get_library_instance('SeleniumLibrary')
            
    def populate_address(self, loc, value):
        """ Populate address with Place Holder aka Mailing Street etc as a locator
            and actual value of the place holder.
        """
        xpath = npsp_lex_locators["mailing_address"].format(loc)
        field = self.selenium.get_webelement(xpath)
        field.send_keys(value)
        
        
    def click_record_button(self, title):
        """ Pass title of the button to click the buttons on the records edit page. Usually save and cancel are the buttons seen.
        """
        locator = npsp_lex_locators['record']['button'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)
        
    def select_tab(self, title):
        """ Switch between different tabs on a record page like Related, Details, News, Activity and Chatter
            Pass title of the tab
        """
        locator = npsp_lex_locators['tab'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)    
        
    def click_special_related_list_button(self, heading, button_title):
        """ To Click on a related list button which would open up a new lightning page rather than a modal.
            Pass the list name and button name
        """
        locator = npsp_lex_locators['record']['related']['button'].format(heading, button_title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        
    def click_dropdown(self, title):
        locator = npsp_lex_locators['record']['list'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()     
    
    def pick_date(self, value):
        """To pick a date from the date picker"""
        locator = npsp_lex_locators['record']['datepicker'].format(value)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click() 
        
#     def select_row(self,value):
#         """To select a row on object page based on name and open the dropdown"""    
#         drop_down = npsp_lex_locators['locating_delete_dropdown'].format(value)
#         self.selenium.get_webelement(drop_down).click()
#         #self.selenium.get_webelement(drop_down).click()

#     def select_row(self,value):
#         """To select a row on object page based on name and open the dropdown"""    
#         locator = npsp_lex_locators['select_name'].format(value)
#         self.selenium.set_focus_to_element(locator)
#         drop_down = npsp_lex_locators['locating_delete_dropdown'].format(value)
#         time.sleep(1)
#         return drop_down
    
    def select_row(self, value):
        """To select a row on object page based on name and open the dropdown"""
        locators = npsp_lex_locators['name']
        list_ele = self.selenium.get_webelements(locators)
        for index, element in enumerate(list_ele):
            if element.text == value:
                drop_down = npsp_lex_locators['locate_dropdown'].format(index + 1)
                self.selenium.get_webelement(drop_down).click()
                time.sleep(1)

    def select_related_row(self, value):
        """To select a row on object page based on name and open the dropdown"""
        locators = npsp_lex_locators['related_name']
        list_ele = self.selenium.get_webelements(locators)
        for index, element in enumerate(list_ele):
            if element.text == value:
                drop_down = npsp_lex_locators['rel_loc_dd'].format(index + 1)
                self.selenium.get_webelement(drop_down).click()
                time.sleep(1)
#     def select_row(self, value ):
#         """To select a row on object page based on name and open the dropdown"""
#         locators = npsp_lex_locators['name']
#         list_ele = self.selenium.get_webelements(locators)
#         index= 1
#         for locator in list_ele:
#             global index
#             if locator.text != value:
#                 index = index+1
#             else:
#                 drop_down = npsp_lex_locators['locate_dropdown'].format(index)
#                 self.selenium.get_webelement(drop_down).click()
#                 self.selenium.get_webelement(drop_down).click()
            
#     def select_related_row(self, value ):
#         """To select row from a related list based on name and open the dropdown"""
#         locators = npsp_lex_locators['related_name']
#         list_ele = self.selenium.get_webelements(locators)
#         index= 1
#         for locator in list_ele:
#             global index
#             if locator.text != value:
#                 index = index+1
#             else:
#                 drop_down = npsp_lex_locators['rel_loc_dd'].format(index)
#                 self.selenium.get_webelement(drop_down).click()
#                 self.selenium.get_webelement(drop_down).click()      
                
    def delete_icon(self, field_name,value):  
        """To click on x """
        locator=npsp_lex_locators['delete_icon'].format(field_name,value)
        self.selenium.get_webelement(locator).click() 
        
    def click_edit_button(self, title):  
        locator=npsp_lex_locators['record']['edit_button'].format(title)
        self.selenium.get_webelement(locator).click()   
        
    def click_id(self, title):  
        locator=npsp_lex_locators['aff_id'].format(title)
        self.selenium.get_webelement(locator).click()     
         
    def select_object_dropdown(self): 
        locator=npsp_lex_locators['object_dd']
        self.selenium.get_webelement(locator).click()   
        
    def check_status(self, acc_name):
        aff_list = npsp_lex_locators['aff_status'].format(acc_name)
        aff_list_text=self.selenium.get_webelement(aff_list).text 
        self.aff_id=npsp_lex_locators['aff_id'].format(acc_name)
        self.aff_id_text=self.selenium.get_webelement(self.aff_id).text
        return self.aff_id_text,aff_list_text     
            
            
    def get_id(self):
        locator=npsp_lex_locators['click_aff_id'].format(self.aff_id_text)
        self.selenium.get_webelement(locator).click()   
        
    def confirm_status(self, field,status):
        locator=npsp_lex_locators['check_status'].format(field,status)
        verify_former=self.selenium.get_webelement(locator).text
        return verify_former
    
    def verify_field_value(self, field,value):
        locator=npsp_lex_locators['check_field'].format(field,value)
        verify_former=self.selenium.get_webelement(locator).text
        return verify_former
    
    def verify_record(self, name):
        """ Checks for the record in the object page and returns true if found else returns false
        """
        locator=npsp_lex_locators['account_list'].format(name)
        self.selenium.page_should_contain_element(locator)

            
    def select_option(self, name):  
        """selects various options in Contact>New opportunity page using name
        """
        locator=npsp_lex_locators['dd_options'].format(name)
        self.selenium.get_webelement(locator).click()
        
    def verify_related_list_items(self,list_name,value):
        """Verifies a specified related list has specified value(doesn't work if the list is in table format)"""
        locator=npsp_lex_locators['related_list_items'].format(list_name,value)
        self.selenium.page_should_contain_element(locator)
    
    def click_span_button(self,title):  
        """clicks on the button under span tag"""      
        locator=npsp_lex_locators['span_button'].format(title)
        self.selenium.get_webelement(locator).click()  
        
    def header_field_value(self,title,value):   
        """Validates if the specified header field has specified value"""   
        locator= npsp_lex_locators['header_field_value'].format(title,value)
        self.selenium.page_should_contain_element(locator)
        
    def Verify_affiliated_contact(self,list_name,first_name,last_name, y):   
        """Validates if the affiliated contacts have the added contact details enter Y for positive case and N for negative case"""   
        locator= npsp_lex_locators['affiliated_contacts'].format(list_name,first_name,last_name)
        if y.upper()=="Y":
            self.selenium.page_should_contain_element(locator)
        elif y.upper()=="N":
            self.selenium.page_should_not_contain_element(locator)
        
    def fill_address_form(self, **kwargs):
        """Validates if the affiliated contacts have the added contact details enter Y for positive case and N for negative case""" 
        for label, value in kwargs.items():
            locator= npsp_lex_locators['manage_hh_page']['address'].format(label,value)
            if label=="Street":
                locator = locator+"textarea"
                self.selenium.get_webelement(locator).send_keys(value)
            else:
                locator = locator+"input"
                self.selenium.get_webelement(locator).send_keys(value)
         
    def Verify_details_address(self,field,value):   
        """Validates if the details page address field has specified value"""   
        locator= npsp_lex_locators['detail_page']['address'].format(field,value)
        self.selenium.page_should_contain_element(locator)        
        
   
    def validate_checkbox(self,name,checkbox_title):   
        """validates all 3 checkboxes for contact on manage hh page and returns locator for the checkbox thats required"""   
          
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBInformal")
        self.selenium.page_should_contain_element(locator)
        
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBFormal")
        self.selenium.page_should_contain_element(locator)
        
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBExName") 
        self.selenium.page_should_contain_element(locator)
        
        if checkbox_title == "Informal Greeting":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBInformal")
        elif checkbox_title == "Formal Greeting":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBFormal") 
        elif checkbox_title.capitalize() == "Household Name":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBExName")       
        return locator
    
    def check_field_value(self, title, value):
        """checks value of a field in details page(section without header)"""
        locator=npsp_lex_locators['detail_page']['verify_field_value'].format(title,value)
        self.selenium.page_should_contain_element(locator)
        
    def click_managehh_button(self,title):  
        """clicks on the new contact button on manage hh page"""      
        locator=npsp_lex_locators['manage_hh_page']['button'].format(title)
        self.selenium.get_webelement(locator).click()    
    
    def select_modal_checkbox(self,title):
        """"""
        locator=npsp_lex_locators['modal']['checkbox'].format(title)
        self.selenium.get_webelement(locator).click()    
        
    def verify_occurance(self,title,value):
        """"""
        locator=npsp_lex_locators['record']['related']['check_occurance'].format(title,value)
        self.selenium.page_should_contain_element(locator)    
     
    def select_related_dropdown(self,title):
        """"""
        locator=npsp_lex_locators['record']['related']['drop-down'].format(title)
        self.selenium.get_webelement(locator).click()   
        
    def get_header_date_value(self,title):   
        """Validates if the specified header field has specified value"""   
        locator= npsp_lex_locators['header_datepicker'].format(title)
        date=self.selenium.get_webelement(locator).text   
        return date 
        
    def get_main_header(self):
        header = self.selenium.get_webelement("//h1/span").text
        return header
    
    def verify_contact_role(self,name,role):
        """verifies the contact role on opportunity page"""
        locator=npsp_lex_locators['opportunity']['contact_role'].format(name,role)
        self.selenium.page_should_contain_element(locator)  
        
    def select_relatedlist(self,title):
        """click on the related list to open it"""
        locator=npsp_lex_locators['record']['related']['title'].format(title)
        self.selenium.get_webelement(locator).click()  
        
    def verify_contact_roles(self, **kwargs):
        """verifies the role of a specific contact on Opportunities page""" 
        for name, value in kwargs.items():
            locator= npsp_lex_locators['object']['contact_role'].format(name,value)
            self.selenium.page_should_contain_element(locator)   
            
    def page_contains_record(self,title):   
        """Validates if the specified record is present on the page"""   
        locator= npsp_lex_locators['object']['record'].format(title)
        self.selenium.page_should_not_contain_element(locator) 
             
                         
               
    def click_special_object_button(self, title):
        locator = npsp_lex_locators['object']['button'].format(title)
        self.selenium.get_webelement(locator).click()
        
    def click_eng_plan_dropdown(self, title):
        locator = npsp_lex_locators['engagement_plan']['dropdown'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        
    def select_eng_plan_checkbox(self,title):
        """"""
        if title=="Skip Weekends":
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("span",title)
            self.selenium.get_webelement(locator).click()
        else:
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("label",title)
            self.selenium.get_webelement(locator).click()
            
    def enter_eng_plan_values(self, **kwargs):
        """Enter values into corresponding fields in Engagement Plan Templet page"""
        for name, value in kwargs.items():
            if name == "Engagement Plan Template Name":
                id = "idName"
                locator = npsp_lex_locators['engagement_plan']['id'].format(id) 
                self.selenium.get_webelement(locator).send_keys(value)     
            elif name == "Description":
                id = "idDesc"
                locator = npsp_lex_locators['engagement_plan']['id'].format(id)
                self.selenium.get_webelement(locator).send_keys(value)  

                
    def enter_task_id_and_subject(self, id, value):
        """Enter values into corresponding task subject fields based on last 2 digits of id"""
        locator = npsp_lex_locators['engagement_plan']['input_box'].format(id) 
        self.selenium.get_webelement(locator).send_keys(value)
    
    
    def click_task_button(self, title):
        if title=="Add Dependent Task":
            id="btnAddDepTask"           
            locator = npsp_lex_locators['engagement_plan']['task_id'].format(id)
            self.selenium.get_webelement(locator).click()    
        elif title=="Add Task":
            id="j_id0:theForm:btnAddTask"
            locator = npsp_lex_locators['engagement_plan']['task_id'].format(id)
            self.selenium.get_webelement(locator).click() 
        elif title=="Save":
            id="j_id0:theForm:j_id5:j_id6:saveBTN"
            locator = npsp_lex_locators['engagement_plan']['task_id'].format(id)
            self.selenium.get_webelement(locator).click()
    
    def check_related_list_values(self,list_name,*args):
        """Verifies the value of custom related list"""
        for value in args:
            locator = npsp_lex_locators['engagement_plan']['check_related_list_item'].format(list_name,value)
            self.selenium.page_should_contain_element(locator)

    def verify_eng_plan_exists(self,name, delete=None):  
        """verifies that the Engagement Plans related list has a plan stored under it and clicks on dropdown if True is passed as 2nd argument"""
        locator = npsp_lex_locators['engagement_plan']['check_eng_plan'].format(name)
        self.selenium.page_should_contain_element(locator) 
        plan=self.selenium.get_webelement(locator).text   
        if delete == "True":
               locator = npsp_lex_locators['engagement_plan']['dd'].format(name)
               self.selenium.get_webelement(locator).click()      
        return plan
    
    def check_activity_tasks(self, *args):
        """verifies that the specified tasks are present under activity tab """
        for value in args:
            locator = npsp_lex_locators['engagement_plan']['tasks'].format(value)
            self.selenium.page_should_contain_element(locator)
