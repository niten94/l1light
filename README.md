# l1light

A shell script that sets the brightness on devices using `login1` D-Bus
interface on Linux. It is made to set screen brightness in GUI sessions as a
regular user without modifying other configuration.

## Installation

Copy `l1light.sh` to a directory included in `$PATH` and rename it to `l1light`
or run `make install`. Script and man page is installed to the home directory
by default in the Makefile.

The programs written below are used but they are usually installed:
- `awk`
- `dbus-send` - setting brightness
- `udevadm` - used with detecting device when not specified

## Similar programs

- [RPigott/blight](https://github.com/RPigott/blight)
  - blight has more features and probably works better
