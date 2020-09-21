CREATE USER inventory WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE inventorydb
    WITH 
    OWNER = inventory
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE USER appo WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE appodb
    WITH 
    OWNER = appo
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE USER apm WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE apmdb
    WITH 
    OWNER = apm
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE USER lcmcontroller WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE lcmcontrollerdb
    WITH 
    OWNER = lcmcontroller
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE USER k8splugin WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE k8splugindb
    WITH 
    OWNER = k8splugin
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

