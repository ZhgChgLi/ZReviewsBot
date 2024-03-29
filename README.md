# ZReviewsBot

## TL;DR

Deprecated, try the new [ZReviewTender](https://github.com/ZhgChgLi/ZReviewTender), powered by brand new [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/list_all_customer_reviews_for_an_app).


-----

ZReviewsBot 為免費、開源專案，幫助您的 App 團隊自動追蹤 App Store (iOS) 及 Google Play (Android) 平台上 App 的最新評價，並發送到指定 Slack Channel 方便您即時了解當前 App 狀況。

![2](doc/images/2.png)

[![Buy Me A Coffe](doc/images/buy.png)](https://www.buymeacoffee.com/zhgchgli)

## 特色

- ✅ 使用更新、更可靠的 API Endpoint 追蹤 iOS App 評價 ([技術細節](https://medium.com/zrealm-ios-dev/appstore-apps-reviews-bot-%E9%82%A3%E4%BA%9B%E4%BA%8B-cb0c68c33994))
- ✅ 支援雙平台評價追蹤 iOS & Android
- ✅ 支援關鍵字通知略過功能 (防洗版廣告騷擾)
- ✅ 客製化設定，隨心所欲
- ✅ 支援使用 Github Action 部署 Schedule 自動機器人

## 安裝及使用

### GEM

1. $ `gem install ZReviewsBot`
2. $ `ZReviewsBot`

### Manually

1. [下載最新版本](https://github.com/ZhgChgLi/ZReviewsBot/releases/latest) 或 Clone 本專案
2. Unzip & $ `cd /ZReviewsBot-X.X.X`
3. Running $ `bundle install` for the first time
4. $ `bundle exec ruby /bin/ZReviewsBot`

## 設定檔配置

1. [下載](https://github.com/ZhgChgLi/ZReviewsBot/blob/main/config.example.yml)或複製專案的 `config.example.yml ` 設定檔範本

2. 更改檔名為 `config.yml`

3. [Android 需要到後台匯出 Google service account key 檔案](https://binx.io/blog/2021/03/07/how-to-create-your-own-google-service-account-key-file/)，並將檔案名改成 `android_publisher_key.json` 放在與 `config.yml` 同個目錄下

4. 使用編輯器打開 `config.yml`

5. 依照各參數說明填妥對應資料

   ```YAML
   iOS:
       appID: 'iOS APP ID'
       appleID: 'APP Store Connect Apple ID (email)'
       password: 'APP Store Connect Apple ID Password'
       notifySlackBotToken: 'slack bot token for iOS new review message'
       notifySlackBotChannelID: 'slack bot target channel id for iOS new review message'
       ignoreKeywords: #list, Optional
           - 'Keyword 1'
           - 'Keyword 2'
   android:
       packageName: 'Android Package Name'
       jsonKeyFileName: 'android_publisher_key.json' # Google service account key file, relative to config.yml file
       notifySlackBotToken: 'slack bot token for android new review message'
       notifySlackBotChannelID: 'slack bot target channel id for android new review message'
       ignoreKeywords: #list, Optional
           - 'Keyword 1'
           - 'Keyword 2'
   setting:
       lang: "en"
       googleTranslateAPIJsonKeyFileName: 'gcp-translate-api-key.json' # Google Translate api key, Optional
       googleTranslateTargetLang: 'zh-TW' # Google Translate api traget lang, Optional
       developerNotifySlackBotToken: 'slack bot token for debug message'
       developerNotifySlackBotChannelID: 'slack bot target channel id for debug message'
   ```

   完成!

## 使用方式

### 執行 iOS App Store 最新評價撈取

`ZReviewsBot -i config.yml`

### 執行 Android Google Play 最新評價撈取

`ZReviewsBot -a config.yml`

### Reset 清除紀錄，重新初始化

`ZReviewsBot -c`

## 執行

![1](doc/images/1.png)

- 第一次執行**僅作初始化**，初始化完成後如有比對到新評價則會開始發送訊息
- iOS 第一次執行須完成 [AppStoreConnect 2步驟登入驗證](https://appstoreconnect.apple.com/)，完成驗證後會將登入資訊儲存在環境變數 `FASTLANE_SESSION` 及檔案 `~/.fastlane/spaceship/iOS APP 開發者帳號 (email)/cookie` 中

完成!

## 使用雲端服務部署排成機器人

iOS 因 Apple Store Connect 會驗證 Session 產生地與執行地有無異動，所以無法在本地產好 Session 然後給 Cloud Server 使用。
![Screen Shot 2021-09-24 at 6 06 33 PM](https://user-images.githubusercontent.com/33706588/134657612-c2f90bc2-43c0-465d-a4e0-08e0403ab359.png)



## 注意事項

- 登入資訊、帳號密碼、Key 均僅在本地使用，不會經過網路傳輸。
- iOS 評價撈取的 Endpoint 需要身份驗證，因蘋果全面實行 2 步驟登入；登入資訊最多只能保持 30 天，每 30 天都須重新登入 & 2步驟驗證，此段是直接依賴 fastlane spaceship 實現。

> Unfortunately there is nothing fastlane can do better in this regard, as these are technical limitations on how App Store Connect sessions are handled.
>
> https://docs.fastlane.tools/best-practices/continuous-integration/#important-note-about-session-duration

## FAQ

- [iOS 評價撈取失敗處理](doc/iOSSessionInvaild.md)


## 誰在使用？

[![Pinkoi Logo](doc/images/use/pinkoi.jpg)](https://www.pinkoi.com/) 
