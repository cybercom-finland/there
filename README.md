# There

There is a tool for storing passwords.

There are a Curses interface and an API.

# General usage

## To access a password, you need

1. Some meta-information about the password, like where it is used
2. The passphrase for a high enough clearance level
3. There.

Use There to search for the password ID and clearance level, and then use 
There to decrypt the password. You will be prompted for the passphrase.

## To store a password, you need 

1. The password, along with as much meta-information as possible
2. There
3. An existing "clearance" level in There
4. A passphrase for that clearance, or any of its superiors.

The tool will prompt you for these when they are needed.

The steps to store a password are:

1. First, you will search (see below) for the password. If it already exists,
   you must update it. Skip down this document a bit for instructions. 
2. Secondly, you need to know which clearance level to use.
3. Then, store the password with the appropriate clearance.

## Finding clearance levels

To list clearance levels and their hierarchy, search for the word "clearance".
A higher up clearance level will have the lower level's passphrase stored on
it.

## Adding new clearance levels 

This should not be done very often, but here's how.

To add a new clearance level, select its place in the hierarchy. Then

1. Choose a suitable passphrase. You know the drill, make it difficult enough.
2. Create the clearance level using There.
3. If there is a higher clearance level, which should be able to access the
   new clearance level, store the passphase for the new level so that it
   be read on the higher level. Make sure it will be found with search terms
   "Passphrase for clearance <clearance name goes here>".
4. If there is a clearance level below the new one, store the passphrase for
   that level on this level. See point 3 above for naming.

## Employee turnover

When an employee leaves the company you may want to change all related 
passwords. To do so, first change the passphrase for the clearance level
(and subsequently, all levels below it), and only the change and store the 
actual passwords.

## Updating passphrases

To change the passphrase of a clearance level, use There. You need to know 
the earlier passphrase. This is a time consuming operation. Make sure
the new passphrase is correctly stored on the higher clearance levels.

## Updating passwords

To update an existing password, you need to

1. search for that password
2. store the new password with the same id.


# Install

## Install prerequisites

  * ncurses-devel

  * Perl modules
  ** Curses
  ** Curses::UI
  ** Math::Pari
  ** Crypt::Random
  ** Crypt::Rijndael
  ** Digest::SHA
  ** Object::Generic
  ** AppConfig


## Install There

```shell
mkdir -p /data00/there
chmod a+rwx,g+s /data00/there

git clone https://.../
make wrapper
make test
sudo make install
```

# Uninstall

```shell
sudo make uninstall
rm -rf /data00/there
```

# Backup

## Read-only backup copy

To create a read-only backup copy on another machine, install There to
another machine and add this to crontab on the backup host.

```
*/15 * * * * rsync -ae ssh --chmod=a-w masterhost:/data00/there /data00/
```
