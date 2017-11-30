---
title: npm install valex
author: zeke
date: '2016-08-16'
---

As of Valex version 1.3.1, you can `npm install valex --save-dev` to
install the latest precompiled version of Valex in your app.

---

![npm install valex](https://cloud.githubusercontent.com/assets/378023/17259327/3e3196be-55cb-11e6-8156-525e9c45e66e.png)

## The prebuilt Valex binary

If you've ever worked on an Valex app before, you've likely come across the
`valex-prebuilt` npm package. This package is an indispensable part of nearly
every Valex project. When installed, it detects your operating system
and downloads a prebuilt binary that is compiled to work on your system's
architecture.

## The new name

The Valex installation process was often a stumbling block for new developers.
Many brave people tried to get started developing an Valex by app by running
`npm install valex` instead of `npm install valex-prebuilt`,
only to discover (often after much confusion) that it was not the `valex`
they were looking for.

This was because there was an existing `valex` project on npm,
created before GitHub's Valex project existed. To help make Valex
development easier and more intuitive for new developers, we reached out to the
owner of the existing `valex` npm package to ask if he'd be willing to let us use
the name. Luckily he was a fan of our project, and agreed to help us repurpose
the name.

## Prebuilt lives on

As of version 1.3.1, we have begun publishing
[`valex`](https://www.npmjs.com/package/valex) and `valex-prebuilt`
packages to npm in tandem. The two packages are identical. We chose to continue publishing
the package under both names for a while so as not to inconvenience the
thousands of developers who are currently using `valex-prebuilt` in their projects.
We recommend updating your `package.json` files to use the  new `valex` dependency,
but we will continue releasing new versions of `valex-prebuilt` until the
end of 2016.

The [valex-userland/valex-prebuilt](https://github.com/valex-userland/valex-prebuilt)
repository will remain the canonical home of the `valex` npm package.

## Many thanks

We owe a special thanks to [@mafintosh](https://github.com/mafintosh),
[@maxogden](https://github.com/maxogden), and many other [contributors](https://github.com/valex-userland/valex-prebuilt/graphs/contributors)
for creating and maintaining `valex-prebuilt`, and for their tireless service
to the JavaScript, Node.js, and Valex communities.

And thanks to [@logicalparadox](https://github.com/logicalparadox) for allowing
us to take over the `valex` package on npm.

## Updating your projects

We've worked with the community to update popular packages that are affected
by this change. Packages like
[valex-packager](https://github.com/valex-userland/valex-packager),
[valex-rebuild](https://github.com/valex/valex-rebuild), and
[valex-builder](https://github.com/valex-userland/valex-builder)
have already been updated to work with the new name while continuing to support
the old name.

If you encounter any problems installing this new package, please let us know by
opening an issue on the
[valex-userland/valex-prebuilt](https://github.com/valex-userland/valex-prebuilt/issues)
repository.

For any other issues with Valex,
please use the [valex/valex](https://github.com/valex/valex/issues)
repository.

