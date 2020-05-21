from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators



@pageobject("Custom", "CustomRollupSettings")
class CustomRollupSettingsPage(BaseNPSPPage, BasePage):
	
	def navigate_to_crlpsettings(self, filter_name=None):
		""" Click on the Navigate CRLP Button and wait for the page to load
		"""
		locator = npsp_lex_locators['id'].format("navigateCRLPs")
		self.selenium.click_element(locator)
		self.selenium.wait_until_location_contains("/one.app", timeout=60,
												   message="custom rollup settings page did not load in 1 min")
		self.selenium.location_should_contain("/one/one.app",
											  message="Current page is not a custom rollup setting view")
	
	def is_setting_present(self, object, name):
		""" Search for the presence of an active crlp setting record already. Return a boolean value accordingly
		"""
		formatted = object+": "+name
		isPresent = False
		search_results = npsp_lex_locators['crlps']['active_setting_record'].format(formatted)
		list_ele = self.selenium.get_webelements(search_results)
		p_count=len(list_ele)
		if p_count == 0:
			print("crlp setting record Not found")
		else:
			isPresent = True
			print("crlp setting already exists")
		return isPresent
	
	@capture_screenshot_on_error
	def create_new_rollup_setting(self, **kwargs):
		""" Wait for the Iframe to be available and switch to the Frame.
		    Confirm that a rollup setting of the same type does not exist
			Click on new and create a new rollup settings record
		"""
		self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
		self.npsp.choose_frame('vfFrameId')
		locator = npsp_lex_locators['crlps']['new_button'].format("New Rollup")
		select_locator = npsp_lex_locators['crlps']['select_locator'].format("Target Object")
		success_toast = npsp_lex_locators['crlps']['success_toast']
		if self.is_setting_present(kwargs['Target Object'], kwargs['Target Field']):
			 return
		else:
			self.selenium.wait_until_page_contains_element(locator)
			new_button = self.selenium.get_webelement(locator)
			self.selenium.click_element(new_button)
			self.selenium.wait_until_page_contains_element(select_locator)
			self.npsp.populate_modal_form(**kwargs)
			self.selenium.click_button("Save")
			self.selenium.wait_until_element_is_not_visible(success_toast)
