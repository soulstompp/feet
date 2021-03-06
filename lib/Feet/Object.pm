package Feet::Object;

use Moose;

use MooseX::AttributeHelpers::Collection::Hash;

has category => (isa => 'Str', is => 'ro'); 

has properties => (
                   metaclass => 'Collection::Hash',
                   isa => 'HashRef[Str]',
                   is => 'rw',
                   default   => sub { {} },
                   provides => {
                                'set'    => 'set_property',
                                'get'    => 'get_property',
                                'empty'  => 'has_properties',
                                'count'  => 'num_properties',
                                'delete' => 'delete_property',
                                'keys'   => 'property_names',
                               },
               );

sub has_property {
    my ($self, $property) = @_;

    return exists $self->properties->{$property};
} 

no Moose;
1;
