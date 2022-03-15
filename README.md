# checkRS-tew
Configuration files for the *tew* (test environment: web) containerized test environment.

### Quick Tips

This directory depends on [pyenv](https://github.com/pyenv/pyenv) for local testing of configuration files and [pipenv](https://github.com/pypa/pipenv) for Python package management.

#### Installing pyenv

Follow the instructions found on the pyenv project's website, https://github.com/pyenv/pyenv#installation or try the curl based, one script install described [here](https://github.com/pyenv/pyenv-installer#prerequisites)

#### Setting up the development environment

Setup the python environment by running:
```bash
make pyenv
```

`python` and `pipenv` commands will be installed.


#### Install the packages from the Pipfile and Pipfile.lock

Pipfile and Pipfile.lock are artifacts of pipenv. They hold details about the versions and SHA256 hashes of packages. Use the following command to install packages into your local pyenv based Python environment:

```
pipenv sync --dev --pre
```

#### Adding new packages to Pipfile and Pipfile.lock

New packages can be added to the Pipfiles with a command like this:

```
pipenv install packagename
```

Where `packagename` is the name of the package you want to install

#### Update all packages in Pipfile.lock

To update all of the Python packages in the Pipfile.lock to their latest versions and install those latest version in the virtualenv, use:

```
pipenv update --dev --pre
```

In the example above, we specify `--dev` to update the main packages and development packages. We also specify `--pre` to allow for pre-released software to be installed. This is particularly needed for the black code formatting package.

### Building the Docker image

Use the Makefile at the top of the repository to build a new Docker image:

```
make build
```
