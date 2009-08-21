#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN { use_ok 'Feet::Extractor' }

my $extractor = Feet::Extractor->new(source => 'General', file_name => '/home/soulstompp/dev/feet/test/etc/config-general.conf');

ok($extractor->extract());
