# dev-container
this will have a docker image that will contain all that is required tools for developing and running tests on it
> We will be using taging for versions

Note that this image is no minimal and includes conan support.
Any dependecies that we need outside of the bulld tools and conan itself will be installed by each repo using package manager.
For now as side above this is only Conan, but may add other options.
