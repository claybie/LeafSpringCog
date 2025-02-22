Tools
========================

## Database Tool
`python dbtool.py`  
`python dbtool.py backup` - creates a whole database backup in `../sql/backups/`  
`python dbtool.py backup lite` - creates a backup only of tables defined in settings  
`python dbtool.py update` - performs an express update with backup and migrations if necessary  
`python dbtool.py update full` - performs a full update with backup and migrations  
`python dbtool.py migrate` - checks and performs any needed migrations

This tool creates or connects to the database defined in `../settings/network.lua`. It 
allows the user to backup or restore the database, import any `custom.sql` 
stored in `../sql/backups/`, and import the latest SQL files provided by LandSandBoat 
Development. This tool also handles data migrations for character data.

## Price Checker
`python price_checker.py`

This tool checks NPC and guild shop prices to see if anything is being sold for less than the buyback price.

## Festive Moogle Tool
`python give_items.py`

This tool is used to distribute the following items:  
- Nomad Cap  
- Moogle Cap  
- Moogle Rod  
- Harpsichord  
- Stuffed Chocobo  
- Tidal Talisman  
- Destrier Beret  
- Chocobo Shirt  

## Announce
`python announce.py "<your message>"`

Sends `<your message>` to every character, in every zone, on every map process.  



Setup
========================

## Installing Dependencies
`emerge -a app-eselect/eselect-repository dev-vcs/git`
`eselect repository add claytabase git https://github.com/claybie/claytabase.git`
`emaint sync -r claytabase`
`emerge -a dev-python/mariadb dev-python/GitPython dev-python/pyyaml dev-python/colorama dev-python/pyzmq dev-python/pylint dev-python/black`

**MariaDB** - MariaDB is required to interact with the database.  
**GitPython** - GitPython is required to compare database versions.  
**PyYAML** - PyYAML is required to read/write settings.  
**Colorama** - Colorama is required to make colored terminal text.  
**zmq** - ZeroMQ is required for sending messages to the server.  
**Pylint** - Pylint is a static code analyser.  
**Black** - Black is a Python code formatter.  

## Other
## TODO: Adapt the below for Gentoo.
`./install-systemd-service.sh` - Installs a systemd service for running the servers on Linux.  
`./run_clang_format.sh` - Formats C++ code. Run from repo root.  
