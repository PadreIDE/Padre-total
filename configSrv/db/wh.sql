BEGIN TRANSACTION;

CREATE TABLE users (
   id          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   username    TEXT UNIQUE NOT NULL,
   email       TEXT UNIQUE NOT NULL,
   password    TEXT NOT NULL
);

CREATE TABLE users_to_roles (
   username INTEGER NOT NULL,
   role INTEGER NOT NULL,
   PRIMARY KEY (username, role),
   FOREIGN KEY(username) REFERENCES users(id),
   FOREIGN KEY(role) REFERENCES roles(id)
);

CREATE TABLE roles (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   role TEXT DEFAULT NULL
);

CREATE TABLE configs (
   id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
   config      TEXT UNIQUE NOT NULL,
   added       DATETIME NOT NULL,
   FOREIGN KEY(id) REFERENCES users(id)
);

INSERT INTO "users" VALUES(1,'friend','fake@email.com', 'foDCGe8hfTtg.');
INSERT INTO "users" VALUES(2,'neighbor','ab@cd.com', 'baxXrXtQl0c6Y');
INSERT INTO "users_to_roles" VALUES(1,1);
INSERT INTO "roles" VALUES(1,'is_admin');
INSERT INTO "configs" VALUES(1, '[]', 'Sun Apr 19 09:19:04 2009');
INSERT INTO "configs" VALUES(2,'$VAR=[]', 'Sun Apr 19 09:19:04 2009');
END TRANSACTION;
