Gem::Specification.new do |gem|
    gem.authors       = ['ZhgChgLi']
    gem.description   = 'ZReviewsBot help you to monitor App Store and Google Play reviews and posts them to Slack.'
    gem.summary       = 'ZReviewsBot help you to monitor App Store and Google Play reviews and posts them to Slack.'
    gem.homepage      = 'https://github.com/zhgchgli0718/ZReviewsBot'
    gem.files         = Dir['locales/*']
    gem.executables   = ['ZReviewsBot']
    gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
    gem.name          = 'ZReviewsBot'
    gem.version       = '0.0.1'
  
    gem.license       = "MIT"
  
    gem.add_dependency 'fastlane', '~> 2.181.0'
    gem.add_dependency 'google-apis-androidpublisher_v3', '~> 0.2.0'
    gem.add_dependency 'googleauth', '~> 0.16.0'
    gem.add_dependency 'net-http', '~> 0.1.0'
    gem.add_dependency 'i18n', '~> 1.8.10'
end