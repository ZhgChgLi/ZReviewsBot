$lib = File.expand_path('../lib', File.dirname(__FILE__))

require 'google/apis/androidpublisher_v3'
require 'googleauth'
require "Slack.rb"
require "Developer.rb"

class GooglePlay
  attr_accessor :packageName, :jsonKeyFilePath, :notifySlackBotToken, :notifySlackBotChannelID, :cacheFile, :ignoreKeywords, :googleTranslateAPIJsonKeyFileName, :googleTranslateTargetLang

  def initialize(config)
    android = config.android
    @googleTranslateAPIJsonKeyFileName = config.setting['googleTranslateAPIJsonKeyFileName']
    @googleTranslateTargetLang = config.setting['googleTranslateTargetLang']

    @packageName = android['packageName']
    @jsonKeyFilePath = android['jsonKeyFilePath']
    @notifySlackBotToken = android['notifySlackBotToken']
    @notifySlackBotChannelID = android['notifySlackBotChannelID']
    @ignoreKeywords = android['ignoreKeywords']
    @cacheFile = "#{$lib}/.cache/.androidLastModified"
  end

  def run()
    app = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
    app.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(jsonKeyFilePath),
      scope: 'https://www.googleapis.com/auth/androidpublisher')

    lastModified = getLastModified()
    newLastModified = lastModified
    
    reviews = []
    isFirst = true
    
    remoteReviews = app.list_reviews(packageName).reviews
    remoteReviews.each { |remoteReview|
      result = {
        "reviewId" => remoteReview.review_id,
        "reviewer" => remoteReview.author_name,
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
        reviews.append(result)
      else
        break
      end
    }

    reviews.sort! { |a, b|  a["lastModified"] <=> b["lastModified"] }
    sendMessagesToSlack(reviews)
    saveLastModified(newLastModified)

    return lastModified
  end

  def sendMessagesToSlack(reviews)
    slack = Slack.new(notifySlackBotToken)
  
    reviews.each { |review|
      if ignoreKeywords != nil
        ignore = false
        ignoreKeywords.each { |ignoreKeyword|
          if review["text"].include? ignoreKeyword
            ignore = true
          end
        }
        next if ignore
      end

      rating = review["starRating"]
      color = rating >= 4 ? "good" : (rating >= 2 ? "warning" : "danger")
      date = "Created at: #{Time.at(review["lastModified"]).to_datetime}"

      stars = "★" * rating + "☆" * (5 - rating)

      attachment = Slack::Payload::Attachment.new
      attachment.color = color
      attachment.author_name = review["reviewer"]
      attachment.footer = "Android(#{review["androidOsVersion"]}) - v#{review["appVersionName"]}(#{review["appVersionCode"]}) - #{review["reviewerLanguage"]} - #{date} - <https://play.google.com/store/apps/details?id=#{packageName}&reviewId=#{review["reviewId"]}|Go To Google Play>"

      needPostOriginal = false
      if review["reviewerLanguage"] != "zh-Hant" && googleTranslateAPIJsonKeyFileName != nil
        googleTranslate = GoogleTranslate.new(googleTranslateAPIJsonKeyFileName, googleTranslateTargetLang)

        attachment.fallback = "#{stars}"
        attachment.title = "[Translate by Google] - #{stars}"
        attachment.text = googleTranslate.translate(review["text"])

        needPostOriginal = true
      else
        attachment.fallback = "#{stars}"
        attachment.title = "#{stars}"
        attachment.text = review["text"]
      end
      
      payload = Slack::Payload.new
      payload.channel = notifySlackBotChannelID
      payload.attachments = [attachment]

      result = slack.pushMessage(payload)

      if result["ok"] == true && result["ts"] != nil && needPostOriginal
        ts = result["ts"]
        
        attachment.fallback = "#{stars}"
        attachment.title = "#{stars}"
        attachment.text = review["text"]

        attachment.footer = "Original message."

        payload.thread_ts = ts
        slack.pushMessage(payload)
      end
    }
 
  end

  def getLastModified() 
    if File.exists?(cacheFile)
      lastModifiedFile = File.open(cacheFile)
      return lastModifiedFile.read.to_i
    else
      return 0
    end
  end

  def saveLastModified(lastModified)
    File.write(cacheFile, lastModified, mode: "w+")
  end

  private :getLastModified, :saveLastModified
end
