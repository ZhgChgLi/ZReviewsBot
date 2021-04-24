require 'yaml'
require "Spaceship"
require 'date'
require "#{__dir__}/SpaceshipExtension.rb"
require "#{__dir__}/Slack.rb"
require "#{__dir__}/Developer.rb"

class AppStore
  attr_accessor :appID, :appleID, :password, :notifyWebHookUrl, :icon_emoji, :username

  def initialize(configFilePath)
    if !File.exists?(configFilePath)
      raise "Config file not found at #{configFilePath}"
    end
    config = OpenStruct.new(YAML.load_file(configFilePath))

    if config.iOS == nil
      raise "iOS node not found at #{configFilePath}"
    end
    if config.iOS['appID'] == nil
      raise "appID not found in iOS node at #{configFilePath}"
    end
    if config.iOS['appleID'] == nil
      raise "appleID not found in iOS node at #{configFilePath}"
    end
    if config.iOS['password'] == nil
      raise "password not found in iOS node at #{configFilePath}"
    end
    if config.iOS['notifyWebHookUrl'] == nil
      raise "notifyWebHookUrl not found in iOS node at #{configFilePath}"
    end
    if config.iOS['icon_emoji'] == nil
      raise "icon_emoji not found in iOS node at #{configFilePath}"
    end
    if config.iOS['username'] == nil
      raise "username not found in iOS node at #{configFilePath}"
    end

    @appID = config.iOS['appID']
    @appleID = config.iOS['appleID']
    @password = config.iOS['password']
    @notifyWebHookUrl = config.iOS['notifyWebHookUrl']
    @icon_emoji = config.iOS['icon_emoji']
    @username = config.iOS['username']
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

        if remoteReview["value"]["lastModified"] > lastModified * 1000 && lastModified != 0
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

  end

  def sendMessagesToSlack(reviews)
    slack = Slack.new(notifyWebHookUrl)
  
    reviews.each { |review|
      rating = review["rating"].to_i
      color = rating >= 4 ? "good" : (rating >= 2 ? "warning" : "danger")
      like = review["helpfulViews"].to_i > 0 ? " - #{review["helpfulViews"]} :thumbsup:" : ""
      date = review["edited"] == false ? "Created at: #{Time.at(review["lastModified"].to_i / 1000).to_datetime}" : "Updated at: #{Time.at(review["lastModified"].to_i / 1000).to_datetime}"

      hasResponse = ""
      if review["developerResponse"] != nil && review["developerResponse"]['lastModified'] < review["lastModified"]
        hasResponse = " (Customer Support Reply outdated)"
      end

      edited = review["edited"] == false ? "" : ":memo: User has updated review#{hasResponse}："
      stars = "★" * rating + "☆" * (5 - rating)

      attachment = Slack::Payload::Attachment.new

      attachment.pretext = edited
      attachment.color = color
      attachment.fallback = "#{review["title"]} - #{stars}#{like}"
      attachment.title = "#{review["title"]} - #{stars}#{like}"
      attachment.text = review["review"]
      attachment.author_name = review["nickname"]
      attachment.footer = "iOS - v#{review["appVersionString"]} - #{review["storeFront"]} - #{date} - <https://appstoreconnect.apple.com/apps/557252416/appstore/activity/ios/ratingsResponses|Go To App Store>"
      
      payload = Slack::Payload.new
      payload.icon_emoji = icon_emoji
      payload.username = username
      payload.attachments = [attachment]

      slack.pushMessage(payload)
      puts "Send #{review["id"]} notifications to slack."
    }
 
  end

  def getLastModified() 
    if File.exists?("#{__dir__}/../.cache/.iOSLastModified")
      lastModifiedFile = File.open("#{__dir__}/../.cache/.iOSLastModified")
      return lastModifiedFile.read.to_i
    else
      return 0
    end
  end

  def saveLastModified(lastModified)
    File.write("#{__dir__}/../.cache/.iOSLastModified", lastModified, mode: "w+")
  end

  private :getLastModified, :saveLastModified
end