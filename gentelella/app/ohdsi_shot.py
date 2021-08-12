from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


class OHDSIShot():
    """ OHDSIShot is a helper library for taking screenshots from the various
    views of OHDSI workspace
    """
    def __init__(self):
        self.options = webdriver.ChromeOptions()
        self.options.headless = True

    def ir_shot(self, url, fname, shoot_element="all", store_path="/tmp"):
        """ Take a screenshot of the incidence rate analysis results
        :param url: the url where the results for incidence rate analysis are
        :param fname: the filename of the screenshot file
        :param shoot_element: choose which specific element to shoot (all for both table and heatmap)
        :param store_path: the path where the screenshot should be stored (default /tmp)
        """

        driver = webdriver.Chrome(options=self.options)

        element_path = {"all": "//div[@class='ir-analysis-results__report-block']",
                        "table":
                            "//div[@class='ir-analysis-results__report-block']/ir-analysis-report/table/tbody/tr/td[1]"}

        driver.get(url)
        element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((
            By.XPATH, "//table[@class='ir-analysis-results__tbl sourceTable']/tbody/tr/td[10]/span/button")))
        element.click()

        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, "//ir-analysis-report")))

        e = driver.find_element_by_xpath(element_path.get(shoot_element))
        size = e.size
        width, height = size['width'], size['height']
        driver.set_window_size(1.5 * width, 1.7 * height)
        e.screenshot("{}/{}".format(store_path, fname))
        driver.quit()

    def cc_shot(self, url, fnames=[], shoot_elements=[], tbls_len=100, store_path="/tmp"):
        """ Take a screenshot of the cohort characterizations results
        :param url: the url where the results for cohort characterization analysis are
        :param fname: the filename of the screenshot file
        :param shoot_elements: list of tuples showing which specific elements to shoot
        (e.g. [("CONDITION / Charlson Index", "chart"), ("DEMOGRAPHICS / Demographics Gender", "table")]
        :param tbls_len: the number of results shown in tables
        :param store_path: the path where the screenshot should be stored (default /tmp)
        """

        driver = webdriver.Chrome(options=self.options)
        driver.set_window_size(1920, 12800)
        driver.get(url)

        # Element type (i.e. table or chart to the proper path extension
        eltype2pathext = {"table": "/div[@class='characterization-view-edit-results__table-wrapper']/div/table",
                          "chart": "/div[@class='characterization-view-edit-results__chart-wrapper']"}

        # Possible values for elements to shoot
        # "All prevalence covariates"
        # "CONDITION / Charlson Index"
        # "DEMOGRAPHICS / Demographics Gender"
        # "DEMOGRAPHICS / Demographics Age Group"
        # "DRUG / Drug Group Era Long Term"

        fnames = fnames if len(fnames) == len(shoot_elements) else ["{}.png".format("_".join(se).replace(
            " / ", "_")) for se in shoot_elements]

        for se in shoot_elements:
            el_path = "//h3[text()='{}']/../div".format(
                se[0])

            WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, el_path)))
            # Show the first 100 results in table
            if se[1] == "table":

                driver.find_element_by_xpath(
                    "{}/div[1]/div[1]/div[@class='dataTables_length']/label/select/option[text()='{}']".format(
                        el_path, tbls_len)).click()

            e = WebDriverWait(driver, 30).until(
                EC.visibility_of_element_located((By.XPATH, "{}{}".format(el_path, eltype2pathext.get(se[1])))))

            e.screenshot("{}/{}".format(store_path, fnames[shoot_elements.index(se)]))

        driver.quit()


    def pathways_shot(self, url, fname, shoot_element="all", store_path="/tmp"):
        """ Take a screenshot of the cohort pathways results
        :param url: the url where the results for pathways analysis are
        :param fname: the filename of the screenshot file
        :param shoot_element: choose which specific element to shoot (all for all tables and charts)
        :param store_path: the path where the screenshot should be stored (default /tmp)
        """

        element_path = {"all": "//div[@class='pathway-results__report-group']"}
        driver = webdriver.Chrome(options=self.options)
        driver.get(url)
        element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH,
                                        "//div[@class='pathway-results__plot-panel panel panel-primary']/div[2]\
                                        /sunburst/div/*[name()='svg']/*[name()='g']/*[name()='g']\
                                        /*[name()='path' and @class='node'][1]")))

        element.click()

        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//table[@class='pathway-results__detail-table table']")))

        e = driver.find_element_by_xpath(element_path.get(shoot_element))
        size = e.size
        width, height = size['width'], size['height']
        driver.set_window_size(1.5 * width, 1.7 * height)
        e.screenshot("{}/{}".format(store_path, fname))
        driver.quit()



# ohdsi_shot = OHDSIShot()
# ohdsi_shot.ir_shot("http://83.212.101.101:8080/atlas/#/iranalysis/100", "ir_100.png")
# ohdsi_shot.pathways_shot("http://83.212.101.101:8080/atlas/#/pathways/27/results/2483", "pw_27_2483.png")
# ohdsi_shot.cc_shot("http://83.212.101.101:8080/atlas/#/cc/characterizations/53/results/2480",
#                    fnames=[], shoot_elements=[
#         ("All prevalence covariates", "table"), ("All prevalence covariates", "chart"),
#         ("CONDITION / Charlson Index", "table"), ("CONDITION / Charlson Index", "chart"),
#         ("DEMOGRAPHICS / Demographics Gender", "table"), ("DEMOGRAPHICS / Demographics Gender", "chart"),
#         ("DEMOGRAPHICS / Demographics Age Group", "table"), ("DEMOGRAPHICS / Demographics Age Group", "chart"),
#         ("DRUG / Drug Group Era Long Term", "table"), ("DRUG / Drug Group Era Long Term", "chart")],
#                    tbls_len=25, store_path="/tmp")