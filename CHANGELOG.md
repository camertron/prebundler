0.11.2
===
- Always run `bundle install` just in case.
- Make sure `bundle check` is the _last_ thing that runs.

0.11.1
===
- Exit with nonzero status code if fallback `bundle install` fails.

0.11.0
===
- Allow the caller to pass in a s3 client for non-standard setups

0.10.0
===
- Update aws-sdk client creation to be able to support non-aws s3 api endpoints (e.g. minio)

0.9.1
===
- Woops, also use platform version when determining the gems that have already been built.
- Fix the subsetter so it outputs gems inside correct source blocks.

0.9.0
===
- Include platform version when uploading gem tarballs to the storage backend (this will cause bundles installed by previous versions of prebundler to be rebuilt).

0.8.1
===
- Fix bug causing config to not be loaded.

0.8.0
===
- Add the subset command for generating subsets of gemfiles.

0.7.2
===
- Fix use of continuation token when listing remote files in S3 backend.

0.7.1
===
- Support git-based gems with non-standard repo names.
- Fix `bundle install` fallback (group args were wrong).

0.7.0
===
- Add prefix option to install command.

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
