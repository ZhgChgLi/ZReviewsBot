require 'net/http'

class Slack
    attr_accessor :notifySlackBotToken
    class Payload
        attr_accessor :channel, :attachments
        class Attachment
            attr_accessor :pretext, :color, :fallback, :title, :text, :author_name, :footer
        
            def as_json(options={})
            {
                pretext: @pretext,
                color: @color,
                fallback: @fallback,
                title: @title,
                text: @text,
                author_name: @author_name,
                footer: @footer
            }
            end
    
            def to_json(*options)
                as_json(*options).to_json(*options)
            end
        end

        def as_json(options={})
        {
            channel: @channel,
            attachments: @attachments
        }
        end

        def to_json(*options)
            as_json(*options).to_json(*options)
        end
    end

    def initialize(notifySlackBotToken)
        @notifySlackBotToken = notifySlackBotToken
    end

    def pushMessage(payload)
        uri = URI("https://slack.com/api/chat.postMessage")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'application/json', 'Authorization': "Bearer #{notifySlackBotToken}"})
        req.body = payload.to_json
        res = http.request(req)
    end

    
end