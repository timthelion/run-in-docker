run-in-docker
-------------

run-in-docker is a simple library which can be used for lifting your IO test cases into a docker container.  It is specifically built to work with `tasty`.

*The problem*:  The Haskell world has many test suits for dealing with pure code.  The funny thing, is that IO is what really needs to be tested, and that's where our test suits are lacking.  I often need to test utilities written in haskell which operate recursively on the file system.  I don't want to find out I've made a mistake after having recursively deleted my home directory!  I'd much prefer to do this dangerous IO stuff in some sort of container.

*The solution*: [docker](http://docker.io) is the bleeding edge of container development.  It requires a very recent kernel and this thing called `cgroups` which is known to significantly slow down your computer.  However, it is not bleading edge out of some lunatic fetish for modernity, what it provides is a kind of virtualization which was simply impossible just a few years ago.  *really fast* and *space efficient* virtualization.

Our final result is very satisfying:  We can test IO code in a *safe* and *reproducable* environment with almost no changes to your test suit code.  Take a look at how your test code might look with vanila [tasty](http://documentup.com/feuerbach/tasty):

````
import Test.Tasty
import Test.Tasty.HUnit

main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [testCase "Some dangerous IO"
                            $ do
                               deleteEveryting
                               deleted <- checkThatEverythingIsDeleted
                               if deleted
                               then return ()
                               else assertFailure "Some things were not deleted."]
````

In order to run this same test code in docker is to:

````
import Test.Tasty
import Test.Tasty.HUnit
import Test.Docker (runInDocker)

main = runInDocker "myDockerImage" $ defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [testCase "Some dangerous IO"
                            $ do
                               deleteEveryting
                               deleted <- checkThatEverythingIsDeleted
                               if deleted
                               then return ()
                               else assertFailure "Some things were not deleted."]
````

That's it! We changed two lines of code and our previously dangerous test case is safely hidden away in a container.

Now for the hard part:

[Installing docker:](http://www.docker.io/gettingstarted/#h_installation)
-------------------

Here are some notes on that:

 - IP forwarding must be enabled: [read about the problem here](https://github.com/dotcloud/docker/issues/866).  Basically, you need to run `sysctl net.ipv4.ip_forward`.
 - On some docker versions you must explicitly pass it a -dns server argument. Ex: `sudo docker -dns 8.8.8.8 run ubuntu ping www.google.com`
 - On debian wheezy, one needs to install the newest kernel availiable from backports.
 - I don't recomend building from source, install from binaries instead!

Once you have docker installed you can:

Launch the docker deamon:
--------------------------

If you installed from a package in say ubuntu, this should be lanuched automatically for you.  If you installed from binaries, you must run(as root)

````
# sysctl net.ipv4.ip_forward
# docker -d
````

All docker commands are issued as root.

Setup a docker image for testing your project in:
-------------------------------------------------

For each project you wish to test, you will create one or more docker images to run your tests in.  You do this by building a docker file.  You should base your docker files on the `Dockerfile` provided in this git repository.  What actually happens when you use `runInDocker` is that your test-suit's binary is copied into the docker image and run there.  All haskell programs need `libgmp` and `libffi` so working off of docker's base `ubuntu` image won't work.

Once you have copied over the provided `Dockerfile` and added any setup code you need, you can build your image with the following command:

````
# docker -dns 8.8.8.8 build .
# sudo docker tag <some-key> myDockerImage
````

*NOTE*: You must replace <some-key> with the key printed out by the `docker build` command!

OK, so you have your docker image built, your test suit prepaired, it's time to get docking(testing)!

Running your tests:
--------------------

To run your tests you issue the standard commands:

````
$ cabal configure --enable-tests
$ cabal build
$ cabal test
````

You will be promted for your password.  If you are not prompted for your password make sure you have sudo installed and are a member of the sudoers group.  If you have any problems, file a bug report!