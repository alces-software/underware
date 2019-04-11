# Flight Architect

## Overview

Tool/library for managing standard config hierarchy and template rendering
for HPC clusters and other openflightHPC tools.

## Installation

For installation instructions please see INSTALL.md

## Configuration

### Supported platforms

* Enterprise Linux 6 distributions: RHEL, CentOS, Scientific Linux (`el6`)
* Enterprise Linux 7 distributions: RHEL, CentOS, Scientific Linux (`el7`)

### Prerequisites

The install scripts handle the installation of all required packages from your
distribution and will install on a minimal base.  For Enterprise Linux
distributions installation of the `@core` and `@base` package groups is
sufficient.

## Operation

Flight Architect is designed to be used both as a library by other openflightHPC tools, and as
an independent tool in its own right. Documentation has not yet been written on
using it as a library; see below for documentation on using it as a tool.

The application can be invoked directly using the `bin` executable:
```
# bin/underware
  NAME:

    underware

  DESCRIPTION:

    Tool for managing standard config hierarchy and template rendering under-lying Alces
clusters and other openflightHPC tools

... etc ...
```

### Creating a new cluster

A new generic cluster can be created using the `init` command. It will ask a few
questions about the cluster such as its name. Then it will generate an
one compute/ ten node cluster.

```
# bin/underware init CLUSTER_IDENTIFIER
Name of the cluster (1/6)
> ?

... etc ..
```

The `CLUSTER_IDENTIFIER` is a label used to manage the cluster from the command
line. All commands that require a cluster input will use this identifier. It is
unrelated to the `cluster_name` which is set by the question. This is to allow
clusters with the same name but different configurations.

#### Creating a bare cluster

The `init` command can also create a cluster without any nodes using the
`--bare` flag. This skips the configuration of the `domain` and any `nodes`.
It does however create the cluster's basic directory structure· It further
configuration needs to use the `configure` commands.

```
# bin/underware init CLUSTER_IDENTIFIER --bare
(no questions asked)
```

### Advanced domain configuration

Once the cluster has been created, further configuration can be done by using
the `configure` commands. The `init` questions can be re-asked by reconfiguring
the domain. Unlike the `init` command, this will not recreate the directory
structure.

```
bin/underware configure domain
```

### Adding new nodes

A set of nodes can be added using the `configure group` command. The `GROUP_NAME`,
and `NODE_RANGE` need to specified on the command line.

```
# bin/underware configure group GROUP_NAME NODE_RANGE
```

Examples:
```
# Configures 'group1' with a single node 'node1'
bin/underware configure group group1 node1

# Configures 'group2' with a range of nodes: 'n01', 'n02', ..., 'n10'
bin/underware configure group group2 n[01-10]
```

Nodes can be added to additional groups using the `--groups` flag

### Configuring a single node

A singe node can be setup using the `configure node` command. It will
either re-configure an existing node, or add an orphan node.

```
# bin/underware configure node NODE_NAME
```

### Rendering the content

The content templates can be rendered using the `template` command. By default
the templates are rendered to:
`/var/lib/underware/clusters/<CLUSTER_IDENTIFIER>/rendered`

```
# bin/underware template
```

## Documentation

- [Templating system](docs/templating-system.md)

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Architect is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
