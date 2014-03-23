# Packer Template

This repository contains [Packer](http://www.packer.io) template for building machine images of [Arch Linux](https://www.archlinux.org/) with [Chef](http://www.getchef.com/).

## Usage

Change variables at `./templates/virtualbox.sh`. And then hit this command.

```
$ ./bin/packer-archlinux generate --path ~ # Generate at home
```
