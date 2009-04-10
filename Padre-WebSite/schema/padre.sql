CREATE TABLE hosts (
    id             INTEGER PRIMARY KEY,
    hostid         VARCHAR(255),
    padre_version  VARCHAR(10),
    first_reported VARCHAR(15),
    latest_report  VARCHAR(15)
);

