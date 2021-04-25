require 'yaml'
require './lib/Slack.rb'

class Developer
  attr_accessor :notifyWebHookUrl

    def initialize(setting)
        @notifyWebHookUrl = setting['developerNotifyWebHookUrl']
    end

    def sendMessagesToSlack(error)
        slack = Slack.new(notifyWebHookUrl)
        attachment = Slack::Payload::Attachment.new
        attachment.color = "danger"
        attachment.fallback = "ZReviewsBot Error accuracy!"
        attachment.title = "ZReviewsBot Error accuracy!"
        attachment.text = error
        attachment.footer = I18n.t('error.error_catch_footer')
        
        payload = Slack::Payload.new
        payload.attachments = [attachment]
        payload.username = 'ZReviewsBot'
        payload.icon_emoji = ':warning:'
      
        slack.pushMessage(payload)
        puts error
    end

    def sendWelcomeMessageToSlack(platform)
        slack = Slack.new(notifyWebHookUrl)
        attachment = Slack::Payload::Attachment.new
        attachment.color = "good"
        attachment.fallback = I18n.t('welcome.title')
        attachment.title = I18n.t('welcome.title')
        attachment.text = I18n.t('welcome.text', :platform => platform)
        attachment.footer = "<https://github.com/zhgchgli0718/ZReviewsBot| Github> - <http://zhgchg.li| ZhgChg.Li>"
        
        payload = Slack::Payload.new
        payload.attachments = [attachment]
        payload.username = 'ZReviewsBot'
        payload.icon_emoji = ':ghost:'
      
        slack.pushMessage(payload)
    end
end
