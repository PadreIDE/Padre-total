CREATE TABLE hosts (
    id             INTEGER PRIMARY KEY,
    private_hostid VARCHAR(255),
    padre_version  VARCHAR(10),
    os             VARCHAR(255),
    perl_version   VARCHAR(255),
    first_reported VARCHAR(15),
    latest_report  VARCHAR(15)
);

CREATE TABLE plugins (
    id             INTEGER PRIMARY KEY,
    name           VARCHAR(255)
);

CREATE TABLE used_plugin (
    plugin    INTEGER,
    host      INTEGER
);
