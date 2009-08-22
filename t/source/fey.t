#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More qw/no_plan/;

use Fey::ORM::Mock;

use Fey::Test;

use Config::General;

BEGIN { use_ok 'Feet::Extractor' }

{
 my $schema = Fey::Test->mock_test_schema_with_fks(); 

 package Schema;

 use Fey::ORM::Schema;

 has_schema $schema;

 package User;

 use Fey::ORM::Table;

 has_table $schema->table('User');

 has_many 'messages' => ( table => $schema->table('Message') );


 package Message;

 use Fey::ORM::Table;

 has_table $schema->table('Message');
 
 has_one $schema->table('User');

 has_many 'messages' => ( table => $schema->table('Message') );

 package Group;

 use Fey::ORM::Table;

 has_table $schema->table('Group');

 package UserGroup;

 use Fey::ORM::Table;

 has_table $schema->table('UserGroup');

 has_one $schema->table('User');
 has_one $schema->table('Group');
}

my $mock = Fey::ORM::Mock->new( schema_class => 'Schema' );

my $conf = Config::General->new('/home/soulstompp/dev/feet/test/etc/config-general.conf');
my %config = $conf->getall();

my %objects;

my (%users, %groups, %messages);

for my $key (keys %{$config{'user'}}) {
    $users{$key} = User->insert(%{$config{'user'}->{$key}}); 
}

for my $key (keys %{$config{'group'}}) {
    $groups{$key} = Group->insert(%{$config{'group'}->{$key}}); 
}

for my $key (keys %{$config{'usergroup'}}) {
    my %record = %{$config{'usergroup'}->{$key}};

    $record{'user_id'} = $users{$record{'user.username'}}->user_id();
    delete $record{'user.username'};

    $record{'group_id'} = $groups{$record{'group.name'}}->group_id();
    delete $record{'group.name'};

    UserGroup->insert(%record); 
}

for my $key (keys %{$config{'message'}}) {
    my %record = %{$config{'message'}->{$key}};

    $record{'user_id'} = $users{$record{'user.username'}}->user_id();
    delete $record{'user.username'};

    delete $record{'feet_unique_id'};

    if (exists $record{'message.feet_unique_id'}) {
        $record{'parent_message_id'} = $messages{$record{'message.feet_unique_id'}}->user_id();
        delete $record{'message.feet_unique_id'};
    }

    $messages{$key} = Message->insert(%record); 
}

my $extractor = Feet::Extractor->new(source => 'Fey', schema_class => 'Schema');

my @objects = $extractor->extract();

use Data::Dumper;
die Dumper \@objects;
