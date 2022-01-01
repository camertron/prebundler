## 0.14.0
* Add `prebundle binstubs` command, which simply invokes `bundle binstubs`.

## 0.13.0
* Support the `eval_gemfile` function in gemfiles.
* Avoid shelling out to the `tar` command.
  - The GNU and BSD versions annoyingly don't accept the same flags, meaning Prebundler can succeed or fail depending on the system it's run on.
  - All tar files are now read and written using pure Ruby.
* Upgrade S3 client to non-EOL version.
* Stop ignoring gems that don't match the current platform.
  - Prebundler shells out to `gem install` when installing individual gems. Older versions of rubygems would fetch gems for the "ruby" platform when the `--ignore-dependencies` option was given, ignoring any platform-specific gems. This resulted in either a) unnecessarily building a bunch of native extensions, or b) installing a gem for the wrong platform (i.e. when no gem existed for the "ruby" platform, eg. helm-rb). I addressed the problem by instructing Prebundler to ignore gems with native extensions, relying on `bundle install` to fix them up. However, the bug has been fixed in modern versions of rubygems, so we can stop ignoring gems.
* Run `bundle lock` before storing or installing gems to make sure the lockfile matches the Gemfile.

## 0.12.0
* Switch out ohai for ohey, which has many fewer dependencies.

## 0.11.8
* Don't store gems in the backend if they failed to install.
* Use an absolute bundle path.
* Only consider a gem from the lockfile if it matches the current platform.
* Fix `#install` methods so they all return true/false.

## 0.11.7
* Fix bug causing platform-specific gems to be installed from source even if they were already present in the backend.

## 0.11.6
* Fix bug causing native extension compile errors.
* Fix bug causing executables to not be included in tarballs.
* Fix bug (maybe introduced by bundler 2?) causing incorrect directory to be tarred. Directory can now include platform apparently.

## 0.11.5
* Add `--retry` flag to CLI (currently does nothing).

## 0.11.4
* Ensure .bundle/config directory exists before writing to it.

## 0.11.3
* Support (well, add stubs for) `ruby` and `git_source` methods in Gemfiles.
* Don't attempt to install gems we can't get a spec for.

## 0.11.2
* Always run `bundle install` just in case.
* Make sure `bundle check` is the _last_ thing that runs.

## 0.11.1
* Exit with nonzero status code if fallback `bundle install` fails.

## 0.11.0
* Allow the caller to pass in a s3 client for non-standard setups

## 0.10.0
* Update aws-sdk client creation to be able to support non-aws s3 api endpoints (e.g. minio)

## 0.9.1
* Woops, also use platform version when determining the gems that have already been built.
* Fix the subsetter so it outputs gems inside correct source blocks.

## 0.9.0
* Include platform version when uploading gem tarballs to the storage backend (this will cause bundles installed by previous versions of prebundler to be rebuilt).

## 0.8.1
* Fix bug causing config to not be loaded.

## 0.8.0
* Add the subset command for generating subsets of gemfiles.

## 0.7.2
* Fix use of continuation token when listing remote files in S3 backend.

## 0.7.1
* Support git-based gems with non-standard repo names.
* Fix `bundle install` fallback (group args were wrong).

## 0.7.0
* Add prefix option to install command.

## 0.6.2
* Provide CLI option to generate binstubs.

## 0.5.2
* Set `BUNDLE_GEMFILE` during prepare step so bundler doesn't complain when we try to call `Bundler.app_config_path`.

## 0.5.1
* Remove pry-byebug require.

## 0.5.0
* Works for a repository with a significant number of dependencies (~ 400).
* Testing on staging server indicates bundle is installed correctly.

## 0.0.4
* Pass bundle path to `gem install`.

## 0.0.3
* Add --with and --without flags to install command.

## 0.0.2
* Better CLI interface.

## 0.0.1
* Birthday!
