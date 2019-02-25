from selenium import webdriver
from selenium.webdriver.common.keys import Keys

driver = webdriver.PhantomJS()

driver.get("http://legacysurvey.org/viewer-dev/ci")

elem_ra = driver.find_element_by_id("ra_input")

elem_ra.clear()

elem_ra.send_keys("200.1")

elem_dec = driver.find_element_by_id("dec_input")

elem_dec.clear()

elem_dec.send_keys("-10.5")

elem_go = driver.find_element_by_id("radec_submit")

elem_go.click()

print(driver.page_source)

driver.close()
