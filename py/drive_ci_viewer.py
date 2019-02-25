from selenium import webdriver
from selenium.webdriver.common.keys import Keys


def get_ci_image_urls(verbose=False):
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

    if verbose:
        print(driver.page_source)

    ci_names = ['CIE', 'CIN', 'CIC', 'CIS', 'CIW']

    image_urls = []
    for ci_name in ci_names:
        elem_image_w = driver.find_element_by_id("image_" + ci_name)

        image_urls.append(elem_image_w.get_attribute("src"))

    driver.close()

    return dict(zip(ci_names, image_urls))
