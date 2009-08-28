package Feet::Implantor;

use Module::Pluggable::Object;

use Moose;

use aliased 'Feet::Implantor::Interface::DestinationDriver';

has destination => ( is => 'ro', isa => 'Str', required => 1, default => 'General' );

has _destination_driver => ( is => 'ro', isa => 'Feet::Implantor::Interface::DestinationDriver', lazy_build => 1 );

has _driver_args => (is => 'ro', isa => 'HashRef', required => 0);

sub BUILDARGS {
    my ($self, %args) = @_;

    my %attributes = %{ $self->meta->get_attribute_map };

    $args{'_driver_args'} = {};
        
    for my $key (keys %args) {
        next if exists $attributes{$key}; 

        $args{'_driver_args'}->{$key} = $args{$key};
        delete $args{$key};
    }

    return \%args;
}

sub _build__destination_driver {
    my ($self) = @_;

    my $class = undef; 
 
    my $base = __PACKAGE__ . '::Destination';

    my $mp = Module::Pluggable::Object->new(
                                            search_path => [$base],
                                           );

    my $class_found = 0;

    for my $class_name ($mp->plugins()) {
        (my $name) = $class_name =~ /^\Q${base}::\E(.+)/;

        if ($name eq $self->destination()) {
            $class = $class_name;
            $class_found = 1;
        }

        last if $class_found;
    }

    confess "Class ${class} in ${base}:: namespace does not appear to exist" unless $class_found;

    Class::MOP::load_class($class);

    unless ($class->does(DestinationDriver)) {
        confess "Class ${class} in ${base}:: namespace does not implement Destination Driver interface";
    }

    my $source_driver = $class->new(%{$self->_driver_args()});

    return $source_driver;
}

sub implant {
    my ($self, $objects) = @_;

    return $self->_destination_driver()->_implant_objects($objects);
}

__PACKAGE__->meta->make_immutable();

1;
