# Extension Spaceship->TunesClient
module Spaceship
    class TunesClient < Spaceship::Client
        def get_recent_reviews(app_id, index)
        r = request(:get, "ra/apps/#{app_id}/platforms/ios/reviews?index=#{index}&sort=REVIEW_SORT_ORDER_MOST_RECENT")
        parse_response(r, 'data')['reviews']
        end
    end
end