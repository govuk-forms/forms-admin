require "capybara/cuprite"
require "selenium/webdriver"

options = Selenium::WebDriver::Chrome::Options.new
options.add_preference(:download, prompt_for_download: false,
                                  default_directory: "/tmp/downloads")

options.add_preference(:browser, set_download_behavior: { behavior: "allow" })

options.add_argument("--disable-features=DeferRendererTasksAfterInput")

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.register_driver :headless_chrome do |app|
  options.add_argument("--headless")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1280,1024")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options:)

  ### Allow file downloads in Google Chrome when headless!!!
  ### https://bugs.chromium.org/p/chromium/issues/detail?id=696481#c89
  bridge = driver.browser.send(:bridge)

  path = "/session/:session_id/chromium/send_command"
  path[":session_id"] = bridge.session_id

  bridge.http.call(:post, path, cmd: "Page.setDownloadBehavior",
                                params: {
                                  behavior: "allow",
                                  downloadPath: "/tmp/downloads",
                                })
  ###

  driver
end

# Capybara's Session#reset! method runs at the end of every test and includes a call to Storage.clearDataForOrigin with
# a wildcard origin argument. As of version 158, Chrome no longer supports the wildcard origin, so this call returns a
# Selenium::WebDriver::Error::InvalidArgumentError and causes the test to fail.
# This code monkey patches the call to Storage.clearDataForOrigin, removes all cookies, and then clears the other
# storage types.
# We can remove this patch once the upstream Capybara issue is fixed: https://github.com/teamcapybara/capybara/issues/2865
module ChromeResetWithoutWildcard
private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    return unless params[:storageTypes].include?("local_storage")

    super(cmd, { origin: Capybara.current_session.server.base_url, storageTypes: "local_storage" })
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithoutWildcard)

Capybara.default_driver = Settings.show_browser_during_tests ? :chrome : :headless_chrome

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, headless: false, browser_options: { "no-sandbox": nil })
end

Capybara.register_driver(:cuprite_headless) do |app|
  Capybara::Cuprite::Driver.new(app, headless: true, browser_options: { "no-sandbox": nil })
end

Capybara.configure do |config|
  config.automatic_label_click = true
end
