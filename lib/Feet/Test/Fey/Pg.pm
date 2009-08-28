package Feet::Test::Fey::Pg;

use strict;
use warnings;

use Test::More;

use DBI;
use File::Spec;
use File::Temp ();

{
    my $DBH;
    sub dbh
    {
        my $class = shift;

        return $DBH if $DBH;

        my $dbh =
            DBI->connect
                ( 'dbi:Pg:dbname=template1', '', '', { PrintError => 0, RaiseError => 1 } );

        eval { $dbh->do( 'DROP DATABASE test_feet' ) };
        $dbh->do( 'CREATE DATABASE test_feet' );

        $dbh =
            DBI->connect
                ( 'dbi:Pg:dbname=test_feet', '', '', { PrintError => 0, RaiseError => 1 } );

        # Shuts up "NOTICE" warnings from Pg.
        local $dbh->{PrintWarn} = 0;
        $class->_run_ddl($dbh);

        return $DBH = $dbh;
    }
}

sub dsn {
    my ($self) = @_;

    return 'dbi:Pg:dbname=test_feet';
}

sub _run_ddl
{
    my $class = shift;
    my $dbh   = shift;

    for my $ddl ( $class->_sql() )
    {
        $dbh->do($ddl);
    }
}

sub _sql
{
    return
        ( <<'EOF',
CREATE TABLE "User" (
    user_id   serial   not null,
    username  text     unique not null,
    email     text     null,
    PRIMARY KEY (user_id)
)
EOF
          <<'EOF',
CREATE TABLE "Group" (
    group_id   serial   not null,
    name       text     not null,
    PRIMARY KEY (group_id),
    UNIQUE (name)
)
EOF
          <<'EOF',
CREATE TABLE "UserGroup" (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id)  REFERENCES "User"  (user_id),
    FOREIGN KEY (group_id) REFERENCES "Group" (group_id)
)
EOF
          <<'EOF',
CREATE TABLE "Message" (
    message_id    serial        not null,
    quality       decimal(5,2)  not null  default 2.3,
    message       varchar(255)  not null  default 'Some message \'" text',
    message_date  date          not null  default NOW(),
/*    parent_message_id  integer  null, */
    user_id       integer       not null,
    PRIMARY KEY (message_id),
/*    FOREIGN KEY (parent_message_id) REFERENCES  "Message" (message_id), */
    FOREIGN KEY (user_id)           REFERENCES  "User"  (user_id)
)
EOF
          <<'EOF',
CREATE VIEW "TestView"
         AS SELECT user_id FROM "User"
EOF
        );
}


1;

__END__
