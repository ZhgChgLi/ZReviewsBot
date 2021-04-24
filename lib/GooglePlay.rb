require 'google/apis/androidpublisher_v3'
require 'googleauth'
require "#{__dir__}/Slack.rb"
require "#{__dir__}/Developer.rb"

class GooglePlay
  attr_accessor :packageName, :jsonKeyFileName, :notifyWebHookUrl, :icon_emoji, :username

  def initialize(configFilePath)
    if !File.exists?(configFilePath)
      raise "Config file not found at #{configFilePath}"
    end
    config = OpenStruct.new(YAML.load_file(configFilePath))

    if config.android == nil
      raise "android node not found at #{configFilePath}"
    end
    if config.android['packageName'] == nil
      raise "packageName not found in android node at #{configFilePath}"
    end
    if config.android['jsonKeyFileName'] == nil
      raise "jsonKeyFileName not found in android node at #{configFilePath}"
    end
    if config.android['notifyWebHookUrl'] == nil
      raise "notifyWebHookUrl not found in android node at #{configFilePath}"
    end
    if config.android['icon_emoji'] == nil
      raise "icon_emoji not found in android node at #{configFilePath}"
    end
    if config.android['username'] == nil
      raise "username not found in android node at #{configFilePath}"
    end

    @packageName = config.android['packageName']
    @jsonKeyFileName = config.android['jsonKeyFileName']
    @notifyWebHookUrl = config.android['notifyWebHookUrl']
    @icon_emoji = config.android['icon_emoji']
    @username = config.android['username']
  end

  def run()
    begin
      app = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
      app.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open("#{__dir__}/../config/#{jsonKeyFileName}"),
        scope: 'https://www.googleapis.com/auth/androidpublisher')

      lastModified = getLastModified()
      newLastModified = lastModified
      
      reviews = []
      isFirst = true
      
      remoteReviews = app.list_reviews(packageName).reviews
      remoteReviews.each { |remoteReview|
        result = {
          "reviewId" => remoteReview.review_id,
          "androidOsVersion" => remoteReview.comments[0].user_comment.android_os_version,
          "appVersionCode" => remoteReview.comments[0].user_comment.app_version_code,
          "appVersionName" => remoteReview.comments[0].user_comment.app_version_name,
          "lastModified" => remoteReview.comments[0].user_comment.last_modified.seconds.to_i,
          "reviewerLanguage" => remoteReview.comments[0].user_comment.reviewer_language,
          "starRating" => remoteReview.comments[0].user_comment.star_rating.to_i,
          "text" => remoteReview.comments[0].user_comment.text.strip
        }

        if isFirst
          isFirst = false
          newLastModified = result["lastModified"]
        end
        
        if result["lastModified"] > lastModified && lastModified != 0  
          # 第一次使用不發通知
          reviews.append(result)
        else
          break
        end
      }

      reviews.sort! { |a, b|  a["lastModified"] <=> b["lastModified"] }
      sendMessagesToSlack(reviews)
      saveLastModified(newLastModified)

    rescue => error
      sendErrorMessage(error)
    end
  end

  def sendMessagesToSlack(reviews)
    slack = Slack.new(notifyWebHookUrl)
  
    reviews.each { |review|
      rating = review["starRating"]
      color = rating >= 4 ? "good" : (rating >= 2 ? "warning" : "danger")
      date = "Created at: #{Time.at(review["lastModified"]).to_datetime}"

      stars = "★" * rating + "☆" * (5 - rating)

      attachment = Slack::Payload::Attachment.new

      attachment.color = color
      attachment.fallback = "#{stars}"
      attachment.title = "#{stars}"
      attachment.text = review["text"]
      attachment.author_name = review["author_name"]
      attachment.footer = "Android(#{review["androidOsVersion"]}) - v#{review["appVersionName"]}(#{review["appVersionCode"]}) - #{review["reviewerLanguage"]} - #{date} - <https://play.google.com/store/apps/details?id=#{packageName}&reviewId=#{review["reviewId"]}|Go To Google Play>"
      
      payload = Slack::Payload.new
      payload.icon_emoji = icon_emoji
      payload.username = username
      payload.attachments = [attachment]

      slack.pushMessage(payload)
      puts "Send #{review["reviewId"]} notifications to slack."
    }
 
  end

  def getLastModified() 
    if File.exists?("#{__dir__}/../.cache/.androidLastModified")
      lastModifiedFile = File.open("#{__dir__}/../.cache/.androidLastModified")
      return lastModifiedFile.read.to_i
    else
      return 0
    end
  end

  def saveLastModified(lastModified)
    File.write("#{__dir__}/.cache/../.androidLastModified", lastModified, mode: "w+")
  end

  def sendErrorMessage(error)
    slack = Slack.new(notifyWebHookUrl)
    attachment = Slack::Payload::Attachment.new
    attachment.color = "danger"
    attachment.fallback = "ZReviewBot Error accuracy!"
    attachment.title = "ZReviewBot Error accuracy!"
    attachment.text = error
    attachment.footer = "<https://docs.fastlane.tools/best-practices/continuous-integration/#important-note-about-session-duration|It may be 2FA session problem.>"
    
    payload = Slack::Payload.new
    payload.attachments = [attachment]
    payload.username = 'ZReviewBot'
    payload.icon_emoji = ':warning:'

    slack.pushMessage(payload)
    puts error
  end

  private :getLastModified, :saveLastModified, :sendErrorMessage
end