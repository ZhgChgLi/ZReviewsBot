require 'yaml'
require './lib/Slack.rb'

class Developer
  attr_accessor :notifyWebHookUrl

    def initialize(configFilePath)
        if !File.exists?(configFilePath)
        raise "Config file not found at #{configFilePath}"
        end
        config = OpenStruct.new(YAML.load_file(configFilePath))

        if config.developer['notifyWebHookUrl'] == nil
            raise "notifyWebHookUrl not found in developer node at #{configFilePath}"
        end
        @notifyWebHookUrl = config.developer['notifyWebHookUrl']
    end

    def sendMessagesToSlack(error)
        slack = Slack.new(notifyWebHookUrl)
        attachment = Slack::Payload::Attachment.new
        attachment.color = "danger"
        attachment.fallback = "ZReviewsBot Error accuracy!"
        attachment.title = "ZReviewsBot Error accuracy!"
        attachment.text = error
        attachment.footer = "<https://docs.fastlane.tools/best-practices/continuous-integration/#important-note-about-session-duration|It may be 2FA session problem.>"
        
        payload = Slack::Payload.new
        payload.attachments = [attachment]
        payload.username = 'ZReviewsBot'
        payload.icon_emoji = ':warning:'
      
        slack.pushMessage(payload)
        puts error
    end
end
