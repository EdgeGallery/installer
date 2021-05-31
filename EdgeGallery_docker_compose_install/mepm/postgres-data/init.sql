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

CREATE USER osplugin WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE osplugindb
    WITH 
    OWNER = osplugin
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
CREATE USER apprulemgr WITH PASSWORD 'te9Fmv%qaq' CREATEDB;
CREATE DATABASE apprulemgrdb
    WITH 
    OWNER = apprulemgr
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;