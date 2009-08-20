package Feet::Implantor;

use Module::Pluggable::Object;

use Moose;

use aliased 'Feet::Implantor::Interface::DestinationDriver';

has destination => ( is => 'ro', isa => 'Str', required => 1, default => 'General' );

has _destinations => ( is => 'ro', isa => 'HashRef[Str]', lazy_build => 1 );

has objects => (
                metaclass => 'Collection::Array', 
                isa => 'ArrayRef[Feet::Object]', 
                is => 'rw', 
                provides => {
                             'push' => 'add_objects',
                             'pop'  => 'remove_last_object',
                            },
               );

sub _build__destinations {
    my ($self) = @_;

    my $base = __PACKAGE__ . '::Source';

    my $mp = Module::Pluggable::Object->new(
                                            search_path => [$base],
                                           ); 

    my @classes = $mp->plugins;

    my %destinations;

    foreach my $class (@classes) {
        Class::MOP::load_class($class);

        unless ($class->does(DestinationDriver)) {
             confess "Class ${class} in ${base}:: namespace does not implement Destination Driver interface";
        }

        (my $name = $class) =~ s/^\Q${base}::\E//;

        $destinations{$name} = $class->new;
    }

    return \%destinations;
}

sub implant_in {
    my ($self, $source_type) = @_;

    return $self->_destinations->{$source_type}->implant();
}

sub can_implant_in {
    my ($self, $source_type) = @_;

    return exists $self->_destinations->{$source_type};
}

__PACKAGE__->meta->make_immutable();

1;
