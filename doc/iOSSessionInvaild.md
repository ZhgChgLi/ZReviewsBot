# iOS 評價撈取失敗處理

iOS 評價撈取的 Endpoint 需要身份驗證，因蘋果全面實行 2 步驟登入；登入資訊最多只能保持 30 天，每 30 天都須重新登入 & 2步驟驗證，此段是直接依賴 fastlane spaceship 實現。

> Unfortunately there is nothing fastlane can do better in this regard, as these are technical limitations on how App Store Connect sessions are handled.
>
> https://docs.fastlane.tools/best-practices/continuous-integration/#important-note-about-session-duration

如果發現 iOS 截取評價時出現錯誤（ `The input stream is exhausted.` ）可以到 Action 查看紀錄，如果出現要求完成 2步驟驗證訊息，則代表目前 Session 已經失效。

## 更新方式

需要更新 `config/FASTLANE_SESSION` 檔中的 cookie ，可透過以下兩個方式更新：

- 使用 `renew_FASTLANE_SESSION.rb` 工具自動完成：

  - Clone 您的 GitHub-action 專案
  - Running $ `bundle install` for the first time
  - 執行 $ `bundle exec ruby renew_FASTLANE_SESSION.rb`
  - 完成驗證步驟
  - Push
  - OK!

- 手動：

  - 藉由 fastlane 的 [spaceship 指令](https://docs.fastlane.tools/best-practices/continuous-integration/#storing-a-manually-verified-session-using-spaceauth)：

    $ `fastlane spaceauth -u app@pinkoi.com`

    並將最後內容貼到 `config/FASTLANE_SESSION` 檔案中，然後 Push。 內容大略如下：

    ```
    ---\n- !ruby/object:HTTP::Cookie\n  name: myacinfo\n  value: \n  domain: apple.com\n  for_domain: true\n  path: "/"\n  secure: true\n  httponly: true\n  expires: \n  max_age: \n  created_at: 2021-05-04 22:02:42.351295000 +08:00\n  accessed_at: 2021-05-04 22:05:16.057030000 +08:00\n- !ruby/object:HTTP::Cookie\n  name: \n  value: ///+pO//+\n  domain: idmsa.apple.com\n  for_domain: true\n  path: "/"\n  secure: true\n  httponly: true\n  expires: \n  max_age: 2592000\n  created_at: &1 2021-05-04 22:02:42.351204000 +08:00\n  accessed_at: *1\n- !ruby/object:HTTP::Cookie\n  name: dqsid\n  value: ..\n  domain: appstoreconnect.apple.com\n  for_domain: false\n  path: "/"\n  secure: true\n  httponly: true\n  expires: \n  max_age: 1800\n  created_at: &2 2021-05-04 22:05:17.780772000 +08:00\n  accessed_at: *2\n
    ```

