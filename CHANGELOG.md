0.6.2
===
- Provide CLI option to generate binstubs.

0.5.2
===
- Set `BUNDLE_GEMFILE` during prepare step so bundler doesn't complain when we try to call `Bundler.app_config_path`.

0.5.1
===
- Remove pry-byebug require.

0.5.0
===
- Works for a repository with a significant number of dependencies (~ 400).
- Testing on staging server indicates bundle is installed correctly.

0.0.4
===
- Pass bundle path to `gem install`.

0.0.3
===
- Add --with and --without flags to install command.

0.0.2
===
- Better CLI interface.

0.0.1
===
- Birthday!
