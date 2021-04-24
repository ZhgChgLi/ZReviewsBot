require "#{__dir__}/lib/AppStore.rb"
require "#{__dir__}/lib/GooglePlay.rb"

CONFIG_FILE = "#{__dir__}/config/config.yml"

developer = Developer.new(CONFIG_FILE)

begin
    appStore = AppStore.new(CONFIG_FILE)
    appStore.run()
rescue => error
    developer.sendMessagesToSlack(error)
end

begin
    googlePlay = GooglePlay.new(CONFIG_FILE)
    googlePlay.run()
rescue => error
    developer.sendMessagesToSlack(error)
end