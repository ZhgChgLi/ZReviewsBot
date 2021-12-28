require 'yaml'
require "google/cloud/translate/v2"

class GoogleTranslate
  attr_accessor :client, :googleTranslateTargetLang

    def initialize(googleTranslateAPIJsonKeyFileName, googleTranslateTargetLang)
        ENV["TRANSLATE_CREDENTIALS"] = googleTranslateAPIJsonKeyFileName
        @client = Google::Cloud::Translate::V2.new
        @googleTranslateTargetLang = googleTranslateTargetLang
    end

    def translate(text)
        #detection = client.detect text
        #sourceLang = detection.language
        #if sourceLang == 'zh-TW' || sourceLang == 'zh-CN'
        #    return text
        #end

        client.translate text, to: googleTranslateTargetLang
    end

end