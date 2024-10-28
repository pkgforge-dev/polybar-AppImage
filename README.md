# polybar-AppImage
Unofficial AppImage of polybar: https://github.com/polybar/polybar

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

Works like the regular polybar, by default running the appimage does the same as running the regular `polybar` binary. 
If you want to use the `polybar-msg` binary, then you would need to pass the arg `msg` to the appimage, for example: 

`polybar-msg cmd restart` would be `nameofappimage msg cmd restart` instead.

You can also symlink the appimage to `PATH` with the name `polybar-msg` and that way it automatically detects and launches `polybar-msg` without extra arguments.

It is possible that this appimage may fail to work with appimagelauncher, I recommend this alternative instead: https://github.com/ivan-hc/AM

This appimage works without fuse2 as it can use fuse3 instead.
