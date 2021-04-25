require 'google/apis/androidpublisher_v3'
require 'googleauth'
require "#{__dir__}/Slack.rb"
require "#{__dir__}/Developer.rb"

class GooglePlay
  attr_accessor :packageName, :jsonKeyFileName, :notifyWebHookUrl, :iconEmoji, :username, :cacheFile, :ignoreKeywords

  def initialize(android)
    @packageName = android['packageName']
    @jsonKeyFileName = android['jsonKeyFileName']
    @notifyWebHookUrl = android['notifyWebHookUrl']
    @iconEmoji = android['iconEmoji']
    @username = android['username']
    @ignoreKeywords = android['ignoreKeywords']
    @cacheFile = File.expand_path(".cache/.androidLastModified")
  end

  def run()
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
    slack = Slack.new(notifyWebHookUrl)
  
    reviews.each { |review|
      ignore = false
      ignoreKeywords.each { |ignoreKeyword|
        if review["text"].include? ignoreKeyword
          ignore = true
        end
      }
      next if ignore

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
      payload.icon_emoji = iconEmoji
      payload.username = username
      payload.attachments = [attachment]

      slack.pushMessage(payload)
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