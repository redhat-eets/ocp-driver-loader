This folder can be used as a cache to hold the driver source.

During the driver build process, the build container will search this folder before it downloads the source package from the driver vendor web site. To accelerate the build speed, one can download the driver source packages and save under this directory brfore `make build`. 
