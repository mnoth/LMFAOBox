create table if not exists members (
    id integer primary key autoincrement,
    name string not null,
    address string not null
);

create table if not exists carriers (
    id integer primary key autoincrement,
    name string not null unique,
    suffix string not null unique
);
