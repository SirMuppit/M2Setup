[![Build Status](https://travis-ci.org/SirMuppit/m2setup.svg?branch=master)](https://travis-ci.org/SirMuppit/m2setup)

# [Deprecated] M2Setup
Magento 2 command line setup script.

This is an interactive script intended to speed up the setup and installation of Magento 2 all via one command. It is
still a work in progress and any contribution will be appreciated. Currently only supports OSX and partially Linux. 

## Deprecated - 19 June 2016
During development on this, I found it very difficult to write certain validation and lookup's within the same script.
It also became much more harder to manage, since everything is in the same file and coming from an OOP background, this
wasn't ideal. I started refactoring the script so that i could include some external scans and validation
([dev/1.0.1](https://github.com/SirMuppit/M2Setup/tree/dev/1.0.1)), but this was also not ideal since it required
multiple source files to exists on the same machine.

After plenty of research and planning, I have decided to rewrite this in my native language PHP, using a
base foundation around the Symfony console component. Please see repo [Mage Utility](https://github.com/SirMuppit/mage-utility)
for further info and progress.

Feel free to continue work on this if you think this approach is a better fit for you.