[![Maven Central](https://img.shields.io/maven-central/v/no.datek/slim-spring-webmvc.svg?label=Maven%20Central)](https://search.maven.org/search?q=g:%22no.datek%22%20AND%20a:%22slim-spring-webmvc%22)

https://github.com/DatekWireless/slim-spring-webmvc

* https://s01.oss.sonatype.org/
* https://s01.oss.sonatype.org/content/repositories/releases/no/datek/
* https://search.maven.org/
* https://search.maven.org/search?q=slim-spring-webmvc

## Usage

There is a reference application at https://github.com/DatekWireless/slim-spring-mvc-sample .

### build.gradle

```groovy
dependencies {
  implementation 'no.datek:slim-spring-webmvc:0.+'
}
```

### Config/Application

```java
@ComponentScan("no.datek.slim")
```

## Building

Requires **JDK 25** (the Gradle toolchain targets Java 25) and builds with **Gradle 9.6**
via the wrapper:

    ./gradlew build

## Update JRuby

Edit `build.gradle` and set the desired JRuby version:

    final String JRUBY_VERSION = '10.0.4.0';


## Update gems

Run the provided script:

        chruby jruby
        jruby ./update_gems.rb

## Release to Maven Central

* Bump the version in build.gradle and commit and push.
* Go to https://github.com/DatekWireless/slim-spring-webmvc/releases
* Select "Draft a new release"
* Select "Choose a tag"
* Enter the tag for the new version, e.g. "v1.0.2" and **press enter**.
* Click on "Publish release"
* This will trigger a release on https://github.com/DatekWireless/slim-spring-webmvc/actions
* The release is built and published to Maven Central at:
  * https://central.sonatype.com/artifact/no.datek/slim-spring-webmvc
  * https://s01.oss.sonatype.org/#nexus-search;quick~no.datek
* The new package will be available after about 20 minutes.

## Activate the new version in downstream apps (e.g. dlc-server)

Publishing to Maven Central does **not** by itself upgrade the consuming apps. Each app
declares a dynamic version constraint (e.g. `implementation 'no.datek:slim-spring-webmvc:2.+'`
in `build.gradle`), but the resolved version is pinned in `gradle.lockfile`. A new release is
ignored until the lock is rewritten.

In the downstream app (e.g. `dlc-server`):

1. If the release crossed a **major** version, bump the constraint in `build.gradle` to match
   (e.g. `2.+` → `3.+`). Within the same major line, leave it as-is.
2. Make sure the local composite build is **not** overriding the published artifact — the
   `includeBuild '../slim-spring-webmvc'` line in `settings.gradle` must be commented out
   (it is only for local development against a working copy).
3. Refresh the dependency lock so the new version is resolved and pinned:

        ./gradlew --refresh-dependencies --write-locks resolveAndLockAll

4. Verify `gradle.lockfile` now points at the new version, then build/test, commit, and push.
