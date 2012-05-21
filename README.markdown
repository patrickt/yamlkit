YAMLKit
=======

YAMLKit is an Objective-C library wrapping the [LibYAML](http://pyyaml.org/wiki/LibYAML) library.

It is written by Patrick Thomson and licensed under the MIT License.

It is still very preliminary, but can parse YAML and emit some Cocoa data structures.

Thanks to:

* Laurent Sansonetti for the idea and encouragement
* The LibYAML team
* Sebastian Nowicki for bringing this project back from the dead

Getting Started
---------------

YAMLKit.framework requires libyaml.dylib so that it can successfully compile. You can manually do this process by downloading the libyaml distribution from [LibYAML](http://pyyaml.org/wiki/LibYAML), compiling it according to the distribution's instructions, and installing it in the system's library paths.

Alternatively, this process has been automated using a Makefile.  You can automatically download, compile, and install the library into **extras/lib** path.

> $ (cd extras && ./bootstrap && make)

If you wish to use the SVN repository instead of tared distribution:

> $ (cd extras && ./bootstrap --with-scm && make)

Modify the **extras/src/packages.mak** for changing the libyaml distribution path, libyaml SVN path, and/or libyaml SVN revision number
