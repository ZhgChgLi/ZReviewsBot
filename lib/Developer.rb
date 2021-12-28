require 'yaml'
require 'Slack'

class Developer
  attr_accessor :notifySlackBotToken, :notifySlackBotChannelID

    def initialize(setting)
        @notifySlackBotToken = setting['developerNotifySlackBotToken']
        @notifySlackBotChannelID = setting['developerNotifySlackBotChannelID']
    end

    def sendMessagesToSlack(error)
        slack = Slack.new(notifySlackBotToken)
        attachment = Slack::Payload::Attachment.new
        attachment.color = "danger"
        attachment.fallback = "ZReviewsBot Error accuracy!"
        attachment.title = "ZReviewsBot Error accuracy!"
        attachment.text = error
        attachment.footer = I18n.t('error.error_catch_footer')
        
        payload = Slack::Payload.new
        payload.channel = notifySlackBotChannelID
        payload.attachments = [attachment]
      
        slack.pushMessage(payload)
        puts error
    end

    def sendWelcomeMessageToSlack(platform)
        slack = Slack.new(notifySlackBotToken)
        attachment = Slack::Payload::Attachment.new
        attachment.color = "good"
        attachment.fallback = I18n.t('welcome.title')
        attachment.title = I18n.t('welcome.title')
        attachment.text = I18n.t('welcome.text', :platform => platform)
        attachment.footer = "<https://github.com/zhgchgli0718/ZReviewsBot| Github> - <http://zhgchg.li| ZhgChg.Li>"
        
        payload = Slack::Payload.new
        payload.channel = notifySlackBotChannelID
        payload.attachments = [attachment]
      
        slack.pushMessage(payload)
    end
end
