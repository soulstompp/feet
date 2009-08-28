#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More qw/no_plan/;

use Feet::Extractor;

use Feet::Test::Fey::Model::Schema;
use Feet::Test::Fey::Model::User;
use Feet::Test::Fey::Model::Group;
use Feet::Test::Fey::Model::UserGroup;
use Feet::Test::Fey::Model::Message;

BEGIN { use_ok 'Feet::Implantor' }

my $extractor = Feet::Extractor->new(source => 'General', file_name => '/home/soulstompp/dev/feet/test/etc/config-general.conf');

my $objects = $extractor->extract();

my $implantor = Feet::Implantor->new(destination => 'Fey', schema_class => 'Feet::Test::Fey::Model::Schema');

$implantor->implant($objects);
