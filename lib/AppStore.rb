$lib = File.expand_path('../lib', File.dirname(__FILE__))

require "spaceship"
require "SpaceshipExtension.rb"
require "Slack.rb"
require "Developer.rb"
require "GoogleTranslate.rb"

class AppStore
  attr_accessor :path, :appID, :appleID, :password, :notifySlackBotToken, :notifySlackBotChannelID, :cacheFile, :ignoreKeywords, :googleTranslateAPIJsonKeyFileName, :googleTranslateTargetLang

  def initialize(config)
    iOS = config.iOS
    @googleTranslateAPIJsonKeyFileName = config.setting['googleTranslateAPIJsonKeyFileName']
    @googleTranslateTargetLang = config.setting['googleTranslateTargetLang']

    @appID = iOS['appID']
    @appleID = iOS['appleID']
    @password = iOS['password']
    @notifySlackBotToken = iOS['notifySlackBotToken']
    @notifySlackBotChannelID = iOS['notifySlackBotChannelID']
    @ignoreKeywords = iOS['ignoreKeywords']
    @cacheFile = "#{$lib}/.cache/.iOSLastModified"
  end

  def run()
    app = Spaceship::Tunes::login(appleID, password)

    lastModified = getLastModified()
    newLastModified = lastModified
    isFirst = true
    reviews = []
    
    index = 0
    breakWhile = true
    while breakWhile
      remoteReviews = app.get_recent_reviews(appID, index)
      if remoteReviews.length() <= 0
        breakWhile = false
        break
      end

      remoteReviews.each { |remoteReview|
        index += 1
        if isFirst
          isFirst = false
          newLastModified = remoteReview["value"]["lastModified"]
        end

        if remoteReview["value"]["lastModified"] > lastModified && lastModified != 0
          reviews.append(remoteReview["value"])
        else
          breakWhile = false
          break
        end
      }
    end
    
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
          if review["review"].include? ignoreKeyword
            ignore = true
          end
        }
        next if ignore
      end

      rating = review["rating"].to_i
      color = rating >= 4 ? "good" : (rating >= 2 ? "warning" : "danger")
      like = review["helpfulViews"].to_i > 0 ? " - #{review["helpfulViews"]} :thumbsup:" : ""
      date = review["edited"] == false ? "Created at: #{Time.at(review["lastModified"].to_i / 1000).to_datetime}" : "Updated at: #{Time.at(review["lastModified"].to_i / 1000).to_datetime}"

      replyOutdated = ""
      if review["developerResponse"] != nil && review["developerResponse"]['lastModified'] < review["lastModified"]
        replyOutdated = I18n.t('appStore.support_reply_outdated')
      end

      edited = review["edited"] == false ? "" : I18n.t('appStore.review_has_updated', :replyOutdated => replyOutdated)
      stars = "★" * rating + "☆" * (5 - rating)

      attachment = Slack::Payload::Attachment.new
      attachment.pretext = edited
      attachment.color = color
      attachment.author_name = review["nickname"]
      attachment.footer = "iOS - v#{review["appVersionString"]} - #{review["storeFront"]} - #{date} - <https://appstoreconnect.apple.com/apps/557252416/appstore/activity/ios/ratingsResponses|Go To App Store>"

      needPostOriginal = false
      if review["storeFront"] != "TW" && googleTranslateAPIJsonKeyFileName != nil
        googleTranslate = GoogleTranslate.new(googleTranslateAPIJsonKeyFileName, googleTranslateTargetLang)
        translateTitle = googleTranslate.translate(review["title"])
        translateReview= googleTranslate.translate(review["review"])

        attachment.fallback = "#{translateTitle} - #{stars}#{like}"
        attachment.title = "[Translate by Google] - #{translateTitle} - #{stars}#{like}"
        attachment.text = "#{translateReview}"
        
        needPostOriginal = true
      else
        attachment.fallback = "#{review["title"]} - #{stars}#{like}"
        attachment.title = "#{review["title"]} - #{stars}#{like}"
        attachment.text = review["review"]
      end

      payload = Slack::Payload.new
      payload.channel = notifySlackBotChannelID
      payload.attachments = [attachment]

      result = slack.pushMessage(payload)

      if result["ok"] == true && result["ts"] != nil && needPostOriginal
        ts = result["ts"]
        
        attachment.fallback = "#{review["title"]} - #{stars}#{like}"
        attachment.title = "#{review["title"]} - #{stars}#{like}"
        attachment.text = review["review"]

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
