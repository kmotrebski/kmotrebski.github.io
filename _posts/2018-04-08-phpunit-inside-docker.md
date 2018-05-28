---
title:  "Decreasing unit tests feedback loop down to milliseconds with PHPUnit inside Docker"
date:   2018-05-26 12:00:00 +0200
excerpt_separator: <!--more-->
---

Goal of the article is to present a simple and convenient solution for Test Driven Development in PHP inside Docker containers. 

<!--more-->

*This is an initial version of my very first article. Every form of feedback is highly appreciated!*

## Fast feedback, cheap feedback

My ultimate goal while developing is to make the feedback loop as fast and as cheap as possible. The concept of feedback loop in software delivery industry has many levels that you can think of. From high level concepts of effective team communication or A/B experiments to low level components of your delivery pipeline like unit tests. All of these constitutes your process and it has direct impact of how long is your cycle time - one of the best metrics for how robust your organization is.

I like the idea taken from Continuous Delivery approach from the [book of Jez Humble and David Farley](https://www.amazon.com/Continuous-Delivery-Deployment-Automation-Addison-Wesley/dp/0321601912) (highly recommend to everyone to read it). What the authors suggest to measure is a cycle time in the extreme case of introducing single 1 line-of-code change and making it reach users on production.

With this post I will cover the unit tests part of the pipeline, specifically while doing a day-to-day development.
 
### GitHub project

I've created an exemplary project on [Github](https://github.com/kmotrebski/blog-art-20180408). It's a simple web service with an endpoint where it displays an "awesome" number - a random integer from 1 to 100.

Feel free to check it out , run it and play with it. You can run it on your laptop with single command! Same for building, both locally and on [Travis](https://travis-ci.org/kmotrebski/blog-art-20180408).
      
### Your day
  
Let's imagine that you want to introduce a change to the system, that will be 1 line long. You want to change range of generated integers from a range of 1-100 to a range of 1-10. Product owner has a hypothesis that this change will dramatically improve UX of your service. Let's do it quickly so that she can validate her idea! :)
  
I will be following [red-green-refactor](http://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html) cycle of Test Driven Development (TDD). How your day of work is going to look like is:
  
- update a unit test assertion to expect integers from a range of 1-10 instead of current 1-100, [it's this line](https://github.com/kmotrebski/blog-art-20180408/blob/master/tests/php/Unit/Library/LotteryMachineTest.php#L15)
- run single test case and see it fails ("red" part of TDD) as an `AwesomeMachine` is still returning higher numbers
- update the `AwesomeMachine` generator, in my case it's [this line](https://github.com/kmotrebski/blog-art-20180408/blob/master/src/Library/AwesomeMachine.php#L16), so that it returns 1 to 10 integers only
- run test case again and see it passing ("green" part of TDD)
- refactor if you see any opportunities for cleaning the code and run the test again
- run the whole unit test suite so that you are sure you have not broken any parts of the app
- commit and push your work.

To sum up, in best case scenario when your change doesn't break anything you want to run a class test 3 times and the whole test suite 1 time. 

### My needs

What I want from the solution is to be super cheap. To be more specific I want it to be:

- **simple** - easy to understand, to set up and debug, despite level of experience of a developer
- **convenient** - cheap to use, not to require lot of effort like typing, clicking or waiting for start up. I can start new day or story quickly and I am not afraid of rebooting computer if needed.
- **flexible** - allow to run different scope of tests, e.g. to run all tests or single class only
- **antifragile** - ready immediately after I check out project from source control. This way it does not increase "costs" of such events as: new developer joining a team, short term contractor or interviewee, HDD broken, Linux reinstall or starting same project in different directory. 
- **consistent** - no to deal with "works on my machine" problem. I would like all changes to automatically get propagated to all developers machines and work same way everywhere.

## Solutions

The list of solutions I came up with:
   
- type all commands manually in console
- set up a terminal alias
- set up tests in PhpStorm or whatever your IDE is and run tests from there
- write your own helper - **my choice**

Let me elaborate on each of the above and explain why I've chosen to write simple helper.

### Typing commands manually

Let's have a look at what you would have to type in the console if you would like to do it manually. This way we will see what we can automate:
  
{% highlight shell %}
docker run --rm \
    --volume $(pwd):/var/www/html/blog-app \
    kmotrebski/blog-app-1:dev \
    php vendor/phpunit/phpunit/phpunit \
    --bootstrap tests/php/Unit/TestBootstrap.php \
    tests/php/Unit/Controllers/IndexControllerTest.php
{% endhighlight %}

It takes about a minute to type the above assuming that you remember everything by heart. Apart from being time consuming and demotivating it is also a massive waste of one of your most significant resources - number of keystrokes you are going to press during your whole life!

### Terminal alias

Next level of automation is to create terminal alias in `~/.bashrc` file, e.g. an `unittests` alias. This way you would simply type:

{% highlight shell %}
unittests tests/php/Unit/Controllers/IndexControllerTest.php
{% endhighlight %}

What is more you can use command completion for both `unittests` alias and the test file path. So you can just type the beginnings and use `Tab` key. For sure it satisfies **flexible** and **convenient** requirements from my needs list above.

However I find some disadvantages:
- not **antifragile** - requires effort to set it up when you checkout new project
- not **consistent** - it does not automatically gets propagated to other developers machines in case of any changes
- you will have to have many of them in case you work with many projects or have many test suites (e.g. integration tests)

### Set up tests in IDE
 
What you can do more is to set up all tests to be run directly from IDE (I am using PhpStorm).

#### Advantages

 - very convenient, you can use keyboard shortcuts to fire tests
 - you can even make tests to be run automatically after every change in the code - with 1 second latency 
 
#### Disadvantages:

- requires lot of effort to set it up, relatively complex operation that can go wrong easily
- because of the above it is also high risk of lot of time spent on maintenance
- changes does not get propagated automatically to other developers machines
- different version of IDE, operation system or directory structure can bring "works on my machine" problem, it can cause a setup to fail on one machine and to work on another
- IDE as additional intermediary between developer and a system under test

All of the above makes this solution missing many of my initial needs: to be **simple**, **antifragile** and **consistent** with other machines.

### Custom helper script - my choice

The solution I've decided for is to write simple helper script in bash that will work similarly to `~/.bashrc` alias but it will be checked into the source control. 

Usage in CLI is following:

{% highlight shell %}
./tests.sh tests/php/Unit/Controllers/IndexControllerTest.php
{% endhighlight %}
 
In case of my [exemplary project](https://github.com/kmotrebski/blog-art-20180408) the output will be following:
 
{% highlight shell %}
21ae3b0d7ab3db664d2346a158ac377485bc24a512b0273dbcaa90c38fef4c14
PHPUnit 5.7.27 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 23 ms, Memory: 4.00MB

OK (2 tests, 2 assertions)
{% endhighlight %}
 
It simply starts Docker container (see hash in 1st line in the output) and runs the test. If you fire command again then the `21ae3b0d7ab3db664d2346a158ac377485bc24a512b0273dbcaa90c38fef4c14` part will be skipped because container is already running.

If you start the script without specifying a path to be tested:

{% highlight shell %}
./tests.sh
{% endhighlight %}

Than all tests will be run and the container will be killed at the end.

{% highlight shell %}
PHPUnit 5.7.27 by Sebastian Bergmann and contributors.

...                                                                 3 / 3 (100%)

Time: 29 ms, Memory: 4.00MB

OK (3 tests, 1002 assertions)
Killing detached container...79b17e8c07b4
{% endhighlight %}

Simple as that! See code snippet and comments below to check how it works.

#### Pros and cons

I've chosen this solution because it satisfies all my criteria listed above:

- **simple** - can show it to the very beginner and it's 100% clear what happens
- **flexible** - can run whole test suite, subdirectory or single class
- **convenient** - can use command completion to fill in script name and path to the test
- **antifragile** - it is checked in into source control and sits in main directory, I don't have to set up anything else. No IDE configuration or updating `~/bashrc` files.
- **consistent** - works same way on all developers machines and any changes gets automatically propagated

### How it works

The file is located [here](https://github.com/kmotrebski/blog-art-20180408/blob/master/tests.sh) and looks like that:

{% highlight bash %}
#!/bin/bash

# clears CLI terminal
clear

# read value of DOCKER_REG variable
source ./.env

# set basic settings
CONTAINER_NAME="unit_tests"
SCOPE="tests/php/Unit"

# (1) read test scope if provided in command line
if [ "$1" != "" ] ; then
    SCOPE=$1
fi

# (2a) find out if there is a detached container running
DETACHED=$(docker ps --filter "name=${CONTAINER_NAME}" -q | wc -l)

# (2b) start detached container if not started yet
if [ $DETACHED != "1" ] ; then
    docker run \
        -d \
        --volume $(pwd):/var/www/html/blog-app \
        --name ${CONTAINER_NAME} \
        --rm \
        ${DOCKER_REG}/blog-app-1:dev \
        sleep infinity
fi

# (3) run tests
docker exec ${CONTAINER_NAME} vendor/phpunit/phpunit/phpunit \
    --bootstrap tests/php/Unit/TestBootstrap.php \
    --configuration phpunit.xml \
    ${SCOPE}

# (4) kill detached container if no scope provided in CLI
if [ "$1" == "" ] ; then
    printf "Killing detached container..."
    docker kill $(docker ps --filter "name=${CONTAINER_NAME}" -q)
fi
{% endhighlight %}

The code is rather self-explanatory but let me put some comments on it.

`if` statement to determines what scope of tests to use, there is a default specified but its overridden by what you type in a console:

{% highlight bash %}
SCOPE="tests/php/Unit"

if [ "$1" != "" ] ; then
    SCOPE=$1
fi
{% endhighlight %}

Following line evaluates if there is a container running already. It counts list of containers with specific name and store it in a `DETACHED` variable:
{% highlight bash %}
DETACHED=$(docker ps --filter "name=${CONTAINER_NAME}" -q | wc -l)
{% endhighlight %}

It then determines whether to start fresh new container: 

{% highlight bash %}
if [ $DETACHED != "1" ] ; then
    docker run \
        -d \
        --volume $(pwd):/var/www/html/blog-app \
        --name ${CONTAINER_NAME} \
        --rm \
        ${DOCKER_REG}/blog-app-1:dev \
        sleep infinity
fi
{% endhighlight %}

It always takes some time to start up new container. In case of my exemplary project it is about 0.5 second. It is observable time so it is better not to kill container all the time but have it running instead. This way you receive your feedback faster on next runs. I use `sleep` program to keep container running and `-d` flag to make it background.

The last part, just after running tests, is to kill the container if needed:

{% highlight bash %}
if [ "$1" == "" ] ; then
    docker kill $(docker ps --filter "name=${CONTAINER_NAME}" -q)
fi
{% endhighlight %}
Container is killed only if developer wanted to run all the tests (no path passed so `$1` is empty). If there was a path passed then I don't want to kill the container as I will probably run it one more time and I want to save time. Container will be killed when you switch off computer because of `--rm` flag used at starting a container.
 
## Final thoughts

This is the solution that works for me very well. Check it out, play, reflect on it and feed back!

It's important to note that this solution covers [unit tests](https://martinfowler.com/bliki/UnitTest.html) only. These are expected to have zero interactions with other services like databases so all the execution takes place within completely isolated Docker container running PHP only.

Aparat from unit tests projects usually include suites of integration tests, acceptance tests, end-2-end tests, UI tests (e.g. JavaScript on frontend) etc. Each suite may include PHPUnit XML configuration file, Docker Compose definition, other configuration files etc. With this article I am covering unit tests only but I am expecting that other suites sit in the project too. **What is more I have a plan to cover them it in next posts of my blog!**

Also be aware that:

- This solution is designed for daily development purpose. You probably don't want to use this script to run your tests inside CI/CD tools like Travis. Use single `docker run` command instead. Have a look at my build script [here](https://github.com/kmotrebski/blog-art-20180408/blob/master/build.sh#L27-L32). Same command runs tests locally and on Travis.
- I've tested it on Linux Ubuntu `16.04` and Docker `17.05.0-ce` (API `1.29`)
- If you would like to run PHPUnit with code coverage report then change image version from `dev` to `debug`.

### Feedback me

All forms of feedback and challenging this solution are highly appreciated! I treat this blog as an opportunity to grow and learn. 

TIA!

#### Comments

Please comment this article on GitHub in a [dedicated issue I've created](https://github.com/kmotrebski/kmotrebski.github.io/issues/1).
