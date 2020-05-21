from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Custom", "CustomRollupSettings")
class CustomRollupSettingsPage(BaseNPSPPage, BasePage):
	
	def navigate_to_crlpsettings(self):
		""" Click on the Navigate CRLP Button and wait for the page to load
		"""
		locator = npsp_lex_locators['id'].format("navigateCRLPs")
		self.selenium.click_element(locator)
		self.selenium.wait_until_location_contains("/one/one.app", timeout=60,
												   message="custom rollup settings page did not load in 1 min")
		self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
		self.npsp.choose_frame('vfFrameId')
		link=npsp_lex_locators['link-text'].format("Back to NPSP Settings")										   
		self.selenium.wait_until_page_contains_element(link,
											  error="Current page is not a customizable rollups setting view")
	
	def is_rollup_present(self, object, name):
    	""" Search for the presense of the same rollup record. Return a boolean value accordingly
		"""
		formatted = object+": "+name
		isPresent = False
		search_results = npsp_lex_locators['button-text'].format(formatted)
		list_ele = self.selenium.get_webelements(search_results)
		p_count=len(list_ele)
		if p_count == 0:
			print("crlp setting record Not found")
		else:
			isPresent = True
			print("crlp setting already exists")
		return isPresent


	@capture_screenshot_on_error
	def clone_rollup(self,rollup_name, **kwargs):
		""" Clone an existing rollup and edit required fields and save
		"""
		if self.is_setting_present(kwargs['Target Object'], kwargs['Target Field']):
    		return
		else:
			locator = npsp_lex_locators['rollup_options'].format("rollup_name")
			select_locator = npsp_lex_locators['crlps']['select_locator'].format("Target Object")
			success_toast = npsp_lex_locators['crlps']['success_toast']
			self.selenium.scroll_element_into_view(locator)
			self.selenium.click_element(locator)
			self.selenium.wait_until_page_contains("Clone")
			self.selenium.click_link("Clone")
			self.selenium.wait_until_page_contains_element(select_locator)
			self.npsp.populate_modal_form(**kwargs)
			self.selenium.click_button("Save")
			self.selenium.wait_until_element_is_not_visible(success_toast)	
 