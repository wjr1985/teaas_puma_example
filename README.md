# teaas_heroku_example
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

An example Heroku app that demonstrates the functionality of [Teaas](https://github.com/wjr1985/teaas). This project will tend to use experimental / testing branches of Teaas - check the `Gemfile` if you're worried about using experimental features. This will run just fine on the Heroku free tier. I use this currently without issue, although it hasn't gone under a ton of heavy load before.

If you want to run it locally for whatever reason: 

* [Download ImageMagik](http://www.imagemagick.org/script/binary-releases.php) or `brew install ImageMagik` if you're using [homebrew](http://brew.sh/)
* `bundle install`
* `bundle exec ruby main.rb`.

Uses Bootstrap and HAML templates, and is overall janky and hacky, but it works!

# Questions / PRs
Questions and/or PRs are more than welcome. If there is a bug when it comes to an image not being processed correctly, please submit an issue on [Teaas](https://github.com/wjr1985/teaas/issues) instead.

# Credits
The file upload button is based on this awesome [gist](https://gist.github.com/davist11/645816) by [davist11](https://github.com/davist11).
Thanks [crookedneighbor](https://github.com/crookedneighbor) for making the interface a lot nicer and other contributions 

# License
It's MIT. See the LICENSE file.
