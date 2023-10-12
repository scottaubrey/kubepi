# kubepi

This project is a highly opinionated automation for kubernetes running on 2 or more raspberry pis.

The setup is glued together using:
- ubuntu for raspberry pi
- cloud-init (built into ubuntu image)
- k3s kubernetes cluster
- zerotier virtual peer to peer network (for accessing remotely)

## Overview

The scripts in this repo are used to generate configuration needed for a fully automated kubernetes cluster of raspberry pis, and to then flash this to sd card.

## Dependencies

The main requirement on top of a macos userspace is [flash](https://github.com/hypriot/flash) and [yq](https://github.com/mikefarah/yq). Both can be installed with Homebrew.
Finally, if you want to use the zerotier integration, make sure you have an account and a network before starting.

## Usage

create a file called `config.yaml` by copying the `config.yaml.example` file and replacing at least the following keys:

- `user.username` - Your chosen username
- `user.sshPubKey` - Your SSH public key
- `user.passwordHash` - a password hash in a crypt compatible format.
- `zerotier_network` - Your zerotier network (or remove the line from config if not desired)
- `token` - this is a token for your k3s cluster communication. Make it up, but securely. I used [pwgen -s 32](https://sourceforge.net/projects/pwgen/)
- `flux.token` - your github pat token
- `flux.owner` - your github username
- `flux.repository` - your github repository

But review all the values in the config file. Note: some are optional (such as `flux` and `zerotier_network`). The default setup here is for a 3 node cluster, with 1 acting as controlplane

then run `./flash_kubernetes_image.sh node_name` with your sdcard inserted. follow the prompts, wait until it's finished and repeat for all your node sdcards.

Finally, insert the cards in each raspberrypi and turn it on.

## Can I configure this differently?

While there is a certain amount that is configurable, it is mostly an illusion - I use this to make a reproducable test environment for myself and is not tested under other circumstances.

I recommend testing out any non-default configuration as it stands a high chance of not working, and I welcome prs to tidy this up and make it better.
