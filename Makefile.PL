use inc::Module::Install;
  
name           'Feet';
all_from       'lib/Feet.pm';
  
requires       'Fey'  => '0.31';
requires       'Fey::ORM' => '0.27';
requires       'Fey::Loader' => '0.10';
requires       'Config::General' => '2.43';
requires       'YAML' => '0.70';
requires       'Module::Pluggable' => '3.9';
requires       'aliased' => '0.30';
requires       'MooseX::AttributeHelpers' => '0.21';
requires       'MooseX::Params' => '0.02';

test_requires  'Test::Able'  => '0.09';

install_script 'install';
  
WriteAll;
