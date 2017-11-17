## prebundler
Speed up gem installation by prebuilding gems and storing them in S3.

## Installation

`gem install prebundler`

### Why?

If you've ever worked on a large application that has hundreds of dependencies, you have probably felt the pain of running `bundle install` for the first time - it takes forever! This is especially true in the Docker world, where you're basically running `bundle install` for the first time every time. All your dependencies have to be reinstalled even if just one of them changes. This is because Docker images are built as a series of layers. If a layer changes, for example because it contains an altered Gemfile.lock, the entire layer (and all the layers that come after) have to be rebuilt.

Unfortunately bundler doesn't really have a great way of mitigating the problem of having to constantly reinstall a huge number of gems. Sure, you can pass the `--jobs` flag to `bundle install` which will fetch gems in parallel, but because of Ruby's global interpreter lock only the I/O parts of gem installation can be truly parallelized. The slowest gems to install are the ones that need to build native extensions (i.e. extensions written in C) as part of the installation process, which is entirely CPU-bound and can't be parallelized.

So what are your options?

1. **Depend on fewer gems**. Totally valid but often impractical, especially since you may depend on a lot of gems _transiently_, meaning they're pulled in by the dependencies of your dependencies.

2. **Vendor everything**. In other words, store copies of all your gems in the `vendor` directory. That way, you don't have to even run `bundle install` during the Docker build. It'll work great as long as you use the same operating system and architecture in development, production, staging, etc or don't depend on gems with native extensions. By and large, native extensions must be built specifically for the architecture they will run on, meaning the same native extension that runs on Mac OS will not run on Ubuntu Linux.

3. **Bear the pain**. Sure, you could use long `bundle install` times as an [excuse to have fun](https://xkcd.com/303/), but if bundling is, for example, blocking you from releasing a new feature or hotfix then you might be hoping we can do better. Hint: we can.

### Enter Prebundler

Prebundler speeds up gem dependency installation by caching the results of installing each gem, including the results from building native extensions. The first time you run prebundler, it:

1. Installs each gem in Gemfile.lock one at a time
2. Puts the resulting files into a tarball (eg. nokogiri.tar)
3. Uploads the tarballs to S3 or some other storage backend

The second time you run prebundler, it:

1. Sucks down gems en masse from S3 (i.e. lots of parallel I/O)
2. Untars the gems straight onto the filesystem
3. Runs `bundle check` and falls back to `bundle install` if anything's missing

### Ok, but does it work?

For the main repository behind lumosity.com which contains 445 gem dependencies, prebundler reduced the amount of time spent bundling from 6 minutes 7 seconds to 43 seconds on Travis CI. That's an 88% speed increase. On my laptop with 16 cores and an enterprise-grade internet connection, prebundler finished installing the same set of 445 gems in a little over 15 seconds.

Oh I see. You were asking if it installs the gems correctly. The answer is yes. Running `bundle check` found no missing dependencies, and the app can successfully boot and serve traffic.

Ah sorry. You were asking if it's production ready. I'm not ready to make that claim. Prebundler needs to be tested by more people with more diverse use cases before I might consider it production ready. You can help me with that.

### You've convinced me. How do I give Prebundler a try?

So glad you asked. First, create a file called `.prebundle_config` in your repo, usually in the same directory as your Gemfile.lock:

```ruby
Prebundler.configure do |config|
  config.storage_backend = Prebundler::S3Backend.new(
    access_key_id: ENV['S3_ACCESS_KEY'],
    secret_access_key: ENV['S3_SECRET_KEY'],
    bucket: 'my-sweet-bucket',
    region: 'us-east-1'  # or whatever
  )
end
```

Next, modify your Dockerfile to use prebundler instead of bundler (although bundler should be installed too):

```dockerfile
ARG S3_ACCESS_KEY=required           # placeholder
ARG S3_SECRET_KEY=required           # placeholder
ENV S3_ACCESS_KEY ${S3_ACCESS_KEY}   # copy build arg into ENV
ENV S3_SECRET_KEY ${S3_SECRET_KEY}   # copy build arg into ENV

RUN gem install bundler
RUN gem install prebundler && prebundle install
```

Now when you build your Docker image, you'll need to pass two additional build arguments:

```sh
docker build \
  --build-arg S3_ACCESS_KEY=... \
  --build-arg S3_SECRET_KEY=... \
  -t registry.tld/organization/repo:tag \
  ./
```

Then sit back and watch the magic, keeping in mind of course that the first time you do a Docker build prebundler will be extremely slow. Run it again and watch it fly.

### Disclaimer

Remember, everybody's applications are a little different. What works for one doesn't necessarily work for the other. If you don't depend on that many gems with native extensions, then prebundler might not help you very much. I guess what I'm trying to say is, your mileage may vary.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
