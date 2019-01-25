# Installing Alces Underware

## Installing from Git

Underware uses ruby `2.4.1` with a corresponding version of `bundler`. It can
be installed from source using:

```
git clone https://github.com/alces-software/underware.git
cd underware
bundle install
```

## Flight Core Installation

Underware can be installed as a tool to the flight-core environment.

### Automated Installation

- Install Flight Core (if not already installed)

```
yum install https://s3-eu-west-1.amazonaws.com/alces-flight/rpms/flight-core-0.1.0%2B20190121150201-1.el7.x86_64.rpm
```

- The installation script (located at `scripts/install`) has variables that can be optionally set in the curl command.
    - `alces_INSTALL_DIR` - The directory to clone the tool into
    - `alces_VERSION` - The version of the tool to install

- Run the installation script

```
# Standard install
curl https://raw.githubusercontent.com/alces-software/underware/master/scripts/install |/bin/bash

# Installation with variables
curl https://raw.githubusercontent.com/alces-software/underware/master/scripts/install |alces_INSTALL_DIR=/my/install/path/ alces_VERSION=dev-release /bin/bash
```

- Now logout and in again or source `/etc/profile.d/alces-flight.sh`

- Underware can now be run as follows

```
flight underware
```

### Local Installation

Instead of depending on an upstream location, Underware can be installed from a local copy of the repository in the following manner.

- Install Flight Core (if not already installed)

```
yum install https://s3-eu-west-1.amazonaws.com/alces-flight/rpms/flight-core-0.1.0%2B20190121150201-1.el7.x86_64.rpm
```

- Execute the install script from inside the `underware` directory

```
bash scripts/install
```

*Note: Local installations will use the currently checked out branch instead of using the latest release. To override this do `alces_VERSION=branchname bash scripts/install`.*

