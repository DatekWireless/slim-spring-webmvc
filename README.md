[![Maven Central](https://img.shields.io/maven-central/v/no.datek/slim-spring-webmvc.svg?label=Maven%20Central)](https://search.maven.org/search?q=g:%22no.datek%22%20AND%20a:%22slim-spring-webmvc%22)

https://github.com/DatekWireless/slim-spring-webmvc

* https://s01.oss.sonatype.org/
* https://s01.oss.sonatype.org/content/repositories/releases/no/datek/
* https://search.maven.org/
* https://search.maven.org/search?q=slim-spring-webmvc

## Usage

### build.gradle

```groovy
plugins {
  id "com.github.jruby-gradle.base" version "2.1.0-alpha.2"
}

final String JRUBY_VERSION = '9.4.6.0'

dependencies {
  implementation 'no.datek:slim-spring-webmvc:0.+'
  implementation "org.jruby:jruby:$JRUBY_VERSION"
}

jruby { jrubyVersion JRUBY_VERSION }
```

### Config/Application

```java
@ComponentScan("no.datek.slim")
```

## Release to Maven Central

* Bump the version in build.gradle and commit and push.
* Go to https://github.com/DatekWireless/slim-spring-webmvc/releases
* Select "Draft a new release"
* Select "Choose a tag"
* Enter the tag for the new version, e.g. "v0.1.0" and **press enter**.
* Click on "Publish release"
* This will trigger a release on https://github.com/DatekWireless/slim-spring-webmvc/actions
* The release is built and published to Maven Central at
  https://s01.oss.sonatype.org/#nexus-search;quick~no.datek
* The new package will be available after about 10 minutes.
