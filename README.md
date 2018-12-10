# teaas_puma_example

An example Puma app that demonstrates the functionality of [Teaas](https://github.com/wjr1985/teaas). This project will tend to use experimental / testing branches of Teaas - check the `Gemfile` if you're worried about using experimental features.

To run this:
* Download or install ImageMagick. On Ubuntu, you can run `sudo apt-get install libmagickwand-dev`. If you're using [homebrew](http://brew.sh), you can run `brew install ImageMagick`.
* `bundle install`
* `bundle exec ruby main.rb`

Works fine on a VPS. I'm currently using a 1 CPU, 1GB RAM VPS, so if you can find something similar, it should work without issue.

Uses Bootstrap and HAML templates, and is overall janky and hacky, but it works!

# Questions / PRs
Questions and/or PRs are more than welcome. If there is a bug when it comes to an image not being processed correctly, please submit an issue on [Teaas](https://github.com/wjr1985/teaas/issues) instead.

# Credits
The file upload button is based on this awesome [gist](https://gist.github.com/davist11/645816) by [davist11](https://github.com/davist11).
Thanks [crookedneighbor](https://github.com/crookedneighbor) for making the interface a lot nicer and other contributions 
Thanks [jackellenberger](https://github.com/jackellenberger/) for redesigning the results page and adding some awesome Slack functionality

# License
It's MIT. See the LICENSE file.
