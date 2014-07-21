#### Tools You'll Need

Install the following tools to bootstrap your environment

* Install [Git](https://help.github.com/articles/set-up-git)
* Install [VirtualBox](https://www.virtualbox.org/)
* Install [Vagrant](http://www.vagrantup.com/)

#### Clone this repository

From the command line, clone this repository with:

```bash
git clone git@github.com:Spantree/vagrant-puppet-elasticsearch-cluster-example.git
```

#### Set up your vagrant instance

Then initialize your vagrant instance with:

```bash
cd vagrant-puppet-elasticsearch-cluster-example
vagrant plugin install vagrant-hostmanager
vagrant up
```

This will download a base Virtualbox Ubuntu image, set up two virtual machine to run locally, install and configure elasticsearch to run in a unicast clusrer.  You may be required to enter your password at some point so that hostmanager can add an entry for `es1.dev.test.com` and `es2.dev.test.com` to your `/etc/hosts` file.
