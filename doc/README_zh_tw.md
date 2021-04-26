# ZReviewsBot

ZReviewsBot 為免費、開源專案，幫助您自動獲取 App 團隊追蹤 App Store (iOS) 及 Google Play (Android) 平台上 App 的最新評價，並發送到指定 Slack Channel 方便您快速獲取當前 App 評價狀況。

## Installation

### GEM

- `gem install ZReviewsBot`

- run `ZReviewsBot [options]`

### Manually

- Clone or 下載此專案

- Run `./bin/ZReviewsBot [options]`

## Usage

### 從範本產生設定檔

`ZReviewsBot -make`

### 執行 iOS App Store 最新評價撈取

`ZReviewsBot -i config.yml`

### 執行 Android Google Play 最新評價撈取

`ZReviewsBot -a config.yml`

### Reset 清除 Cache 從新開始

`ZReviewsBot -c`