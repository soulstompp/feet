package Feet::Implantor::Interface::Destination::Driver;

use Moose::Role;

use namespace::clean -except => 'meta';

has objects => (
                metaclass => 'Collection::Array', 
                isa => 'ArrayRef[Feet::Object]', 
                is => 'rw', 
                provides => {
                             'push' => 'add_objects',
                             'pop'  => 'remove_last_object',
                            },
               );

requires '_implant_objects';

1;
