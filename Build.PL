use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new( 
                                  module_name          => 'Feet',
                                  license              => 'lgpl',
                                  requires             => {
                                                           'Fey' => '0.31',
                                                           'Fey::ORM' => '0.27',
                                                           'Fey::Loader' => '0.10',
                                                           'Config::General' => '2.43',
                                                           'Module::Pluggable' => '3.9',
                                                           'aliased' => '0.3',
                                                           'MooseX::AttributeHelpers' => '0.21',
                                                          },
                                  build_requires       => {
                                                           'Fey::Test' => '0.06',
                                                           'Test::Able' => '0.02',
                                                          },
                                  recommends           => {
                                                           'YAML' => '0.70',
                                                          },
                                  create_makefile_pl   => 'traditional',
                                  create_readme        => 1,
                                  sign                 => 1,
                                  recursive_test_files => 1,
                                 );

$builder->create_build_script(); 
