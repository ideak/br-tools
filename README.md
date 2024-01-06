# BR-TOOLS

Simple tools to mount/unmount and chroot into a root filesystem image, for
instance created with
[Buildroot](https://github.com/buildroot/buildroot).

After creating the root filesystem image, you can configure these tools
via the [.br.rc](br-example.rc) file in your home directory. This config
file specifies the location of the chroot directory, the root filesystem
to be mounted at this location with additional filesystems to be mounted
under this root filesystem and the home directory to be used in the
chroot shell.

See an example example [.bashrc](br-bashrc-example) you can use added to
your chroot home directory.
