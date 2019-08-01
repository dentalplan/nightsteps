# nightsteps


## dependencies

Ongoing list tbc

Debian modules
* libdbi-perl - DBI perl
* libdbd-pg-perl - postgre drivers for perl
* python-pyproj
* gpsd
* postgresql 
* libpq-dev 
* postgresql-client
* postgresql-server-dev-XX - postgre dev server (XX is version number)
* python-psycopg2

Perl libraries
* DBI
* DBI::Pg
* Math::Polygon
* Math::Polygon::Calc
* Switch
* Time::Piece
* Time::HiRes
* Net::GPSD3
* Data::Dumper

Python libraries
* gpiozero
* mag3110
* smbus
* pyproj\*
* psycopg2
* Adafruit\_GPIO.SPI
* Adafruit\_MCP3008


Directories to make
/home/pi/nsdata
/home/pi/nsdata/gpio
/home/pi/nsdata/log
/home/pi/nsdata/sys

Steps needed to set up Pi for use
* Enable SPI and I2C interfaces using raspi-config


**Setting up Postgre SQL**

as postgres user in postgres database
* CREATE ROLE ldd login nosuperuser inherit nocreatedb nocreaterole noreplicationi
* CREATE DATABASE ldd OWNER ldd
* CREATE SCHEMA app\_ldd AUTHORIZATION ldd;

as postgres user in ldd database
* CREATE EXTENSION postgis;
* CREATE EXTENSION postgis\_topology;

as postgres user from command line, in directory with LDD sql extract (obtainable here :
pg\_restore --clean -d <LDD_DATABASE> ldddata\_20170609.sql.tar

change the following line in pg_hba.conf:
local   all    all     peer
to:
local   all    all     md5

then as postgres user in postgres database:
* grant all privileges on database ldd to pi;
* grant usage on schema app\_ldd to pi;
* ALTER USER pi WITH PASSWORD '30ki24tpoppyli6'

Then run the following from the database /home/pi/nightsteps/dataprocessing/
python convertGeoLatLon.py all


